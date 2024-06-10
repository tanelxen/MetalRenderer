//
//  BrushBoundsTool.swift
//  Sandbox
//
//  Created by Fedor Artemenkov on 09.06.2024.
//

import Foundation
import Metal
import simd

/*
 Drag mesh faces along normals
 In 2D tap inside mesh allows drag entire mesh
 */
final class BrushBoundsTool
{
    private let viewport: Viewport
    var mesh: PlainBrush?
    
    private var gridSize: Float = 8
    private var dragOrigin: float3?
    
    private var dragType: DragType = .none
    
    // For render edges
    private let box = MTKGeometry(.box)
    
    init(viewport: Viewport)
    {
        self.viewport = viewport
    }
    
    func update()
    {
        guard let mesh = self.mesh else { return }
        
        guard Mouse.IsMouseButtonPressed(.left)
        else {
            
            switch dragType
            {
                case .none:
                    return

                case .mesh(let mesh):
                    for face in mesh.faces
                    {
                        let normal = mesh.planes[face.planeIndex].normal
                        mesh.planes[face.planeIndex].distance = dot(normal, face.center)
                    }
                    
                    mesh.faces.forEach {
                        $0.update(from: mesh.planes)
                    }

                case .face(let face):
                    let normal = mesh.planes[face.planeIndex].normal
                    mesh.planes[face.planeIndex].distance = dot(normal, face.center)
                    
                    mesh.faces.forEach {
                        $0.update(from: mesh.planes)
                    }
            }
            
            mesh.center = mesh.faces.map({ $0.center }).reduce(.zero, +) / Float(mesh.faces.count)
            
            dragOrigin = nil
            dragType = .none
            return
        }
        
        let ray = viewport.mousePositionInWorld()
        
        // Плоскость, на которую будем проецировать луч, по ней будем перемещаться
        let viewNormal = viewport.camera!.transform.rotation.forward
        let plane = Plane(normal: viewNormal, distance: dot(mesh.center, viewNormal))
        
        // Куда мы сейчас указываем
        let point = intersection(ray: ray, plane: plane)!
        
        if let dragOrigin = dragOrigin
        {
            var delta = point - dragOrigin
            
            delta = floor(delta / gridSize + 0.5) * gridSize
            
            // We don't want to shear face
            if case let .face(face) = dragType
            {
                let normal = mesh.planes[face.planeIndex].normal
                delta = delta * abs(normal)
            }
            
            guard length(delta) > 0 else { return }
            
            switch dragType
            {
                case .none:
                    return
                    
                case .mesh(let mesh):
                    for face in mesh.faces
                    {
                        for i in face.points.indices
                        {
                            face.points[i] += delta
                        }
                    }
                    
                case .face(let face):
                    for i in face.points.indices
                    {
                        face.points[i] += delta
                    }
                    
//                    mesh.recalculateUV()
            }
            
            self.dragOrigin = dragOrigin + delta
        }
        else
        {
            if viewport.viewType != .perspective
            {
                guard let rayPoint = closestPoint(on: ray, to: mesh.center)
                else {
                    return
                }
                
                dragOrigin = point
                dragType = .mesh(mesh)
                
                // Perpendicular ray to center of mesh from point on mouse ray
                let rayToOrigin = Ray(
                    origin: rayPoint,
                    direction: normalize(mesh.center - rayPoint)
                )

                for face in mesh.faces
                {
                    if intersect(ray: rayToOrigin, face: face)
                    {
                        dragType = .face(face)
                        break
                    }
                }
            }
        }
    }
    
    func draw(with renderer: ForwardRenderer)
    {
        switch dragType
        {
            case .none:
                return
                
            case .mesh(let mesh):
                for face in mesh.faces
                {
                    for i in face.points.indices
                    {
                        let p1 = face.points[i]
                        let p2 = face.points[(i + 1) % face.points.count]
                        drawEdge(p1: p1, p2: p2, color: [1, 1, 0, 1], with: renderer)
                    }
                }
                
            case .face(let face):
                for i in face.points.indices
                {
                    let p1 = face.points[i]
                    let p2 = face.points[(i + 1) % face.points.count]
                    drawEdge(p1: p1, p2: p2, color: [1, 1, 0, 1], with: renderer)
                }
        }
    }
    
    private func drawEdge(p1: float3, p2: float3, color: float4, with renderer: ForwardRenderer)
    {
        let boxMainAxis = float3(0, 1, 0)
        
        let direction = normalize(p2 - p1)
        let position = (p1 + p2) * 0.5
        let length = length(p2 - p1)
        
        // Orient Y-axis of box along edge
        let q = simd_quatf(from: boxMainAxis, to: direction)
        let matrix = float4x4(q)
        
        var renderItem = RenderItem(mtkMesh: box)
        
        renderItem.isSupportLineMode = false
        renderItem.tintColor = color
        
        renderItem.transform = Transform(position: position)
        renderItem.transform.scale = [0.5, length, 0.5]
        renderItem.transform.parent = matrix
        
        renderer.add(item: renderItem)
    }
}

private enum DragType
{
    case none
    case mesh(_ mesh: PlainBrush)
    case face(_ face: BrushFace)
}

private func intersect(ray: Ray, face: BrushFace) -> Bool
{
    let n = face.plane.normal

    if dot(n, ray.direction) > 0 {
        return false
    }
    
    let d = ray.origin - face.center
    let t = -dot(n, d) / dot(n, ray.direction)
    
    if t < 0 {
        return false
    }
    
    let p = ray.origin + ray.direction * t
    
    var inside = true
    
    for i in face.points.indices
    {
        let v0 = face.points[i]
        let v1 = face.points[(i + 1) % face.points.count]
        
        let e = cross(v1 - v0, p - v0)
        
        inside = inside && dot(e, n) < 0
    }
    
    return inside
}

private func closestPoint(on ray: Ray, to point: float3) -> float3?
{
    let v = point - ray.origin
    
    let t = dot(v, ray.direction)
    
    guard t >= 0 else {
        return nil
    }
    
    let e = ray.origin + ray.direction * t
    
    return e
}

