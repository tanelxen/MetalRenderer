//
//  ObjectTool.swift
//  Sandbox
//
//  Created by Fedor Artemenkov on 28.05.2024.
//

import Foundation
import Metal
import simd

// Манипуляция над объектом выделенным мешем.
// При клике внутри области и драге - перемешение меша
// При клике вне области и драге - перемещение ближайшей грани
final class ObjectTransformTool
{
    private let viewport: Viewport
    var mesh: EditableMesh?
    
    private var gridSize: Float = 8
    private var dragOrigin: float3?
    
    private var dragType: DragType = .none
    
    private var dotsVertexBuffer: MTLBuffer!
    
    init(viewport: Viewport)
    {
        self.viewport = viewport
        
        let length = MemoryLayout<Vertex>.stride * MAX_VERTS
        dotsVertexBuffer = Engine.device.makeBuffer(length: length)
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
                        face.plane.distance = dot(face.plane.normal, face.center)
                    }
                    
                case .face(let face):
                    face.plane.distance = dot(face.plane.normal, face.center)
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
                delta = delta * abs(face.plane.normal)
            }
            
            guard length(delta) > 0 else { return }
            
            switch dragType
            {
                case .none:
                    return
                    
                case .mesh(let mesh):
                    for face in mesh.faces
                    {
                        for vert in face.verts
                        {
                            vert.position += delta
                        }
                    }
                    
                case .face(let face):
                    for vert in face.verts
                    {
                        let iter = VertexEdgeIterator(vert)
                        
                        while let twin = iter.next()?.vert
                        {
                            twin.position += delta
                        }
                    }
                    
                    mesh.recalculateUV()
            }
            
            self.dragOrigin = dragOrigin + delta
        }
        else
        {
            if let d = distance(ray: ray, point: mesh.center), d < 16
            {
                dragOrigin = point
                dragType = .mesh(mesh)
            }
            else
            {
                for face in mesh.faces
                {
                    guard abs(dot(face.plane.normal, ray.direction)) < 0.01
                    else {
                        continue
                    }
                    
                    if let d = distance(ray: ray, point: face.center), d < 16
                    {
                        dragOrigin = point
                        dragType = .face(face)
                        break
                    }
                }
            }
        }
    }
    
    func draw(with renderer: ForwardRenderer)
    {
        var vertices: [Vertex] = []
        
        switch dragType
        {
            case .none:
                return
                
            case .mesh(let mesh):
                for face in mesh.faces
                {
                    vertices.append(
                        Vertex(pos: face.center, clr: [0, 1, 0, 1])
                    )
                }
                
            case .face(let face):
                vertices.append(
                    Vertex(pos: face.center, clr: [0, 1, 0, 1])
                )
        }
        
        var renderItem = RenderItem(technique: .dot)
        
        renderItem.cullMode = .none
        renderItem.isSupportLineMode = true
        renderItem.primitiveType = .point
        
        var pointer = dotsVertexBuffer.contents().bindMemory(to: Vertex.self, capacity: MAX_VERTS)
        
        for vertex in vertices
        {
            pointer.pointee = vertex
            pointer = pointer.advanced(by: 1)
        }
    
        renderItem.vertexBuffer = dotsVertexBuffer
        renderItem.numVertices = vertices.count
        
        renderer.add(item: renderItem)
    }
}

private enum DragType
{
    case none
    case mesh(_ mesh: EditableMesh)
    case face(_ face: Face)
}

private func distance(ray: Ray, point: float3) -> Float?
{
    let v = point - ray.origin
    
    let t = dot(v, ray.direction)
    
    guard t >= 0 else {
        return nil
    }
    
    let e = ray.origin + ray.direction * t
    
    return length(e - point)
}

private struct Vertex
{
    var pos: float3 = .zero
    var clr: float4 = .one
}

private let MAX_VERTS: Int = 16
