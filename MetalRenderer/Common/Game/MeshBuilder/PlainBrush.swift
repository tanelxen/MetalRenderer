//
//  WorldBrush.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 20.04.2024.
//

import Metal
import simd

final class PlainBrush: EditableObject
{
    var transform: Transform = Transform()
    
    var isSelected = false {
        didSet {
            selectedFaceIndex = nil
        }
    }
    
    var worldPosition: float3 {
        faces.first?.points.first ?? .zero
    }
    
    var selectedFacePoint: float3?
    var selectedFaceAxis: float3?
    var selectedEdgePoint: float3?
    var selectedEdgeAxis: float3?
    
    var isRoom = false
    
    var texture: String = ""
    
    var center: float3 = .zero
    
    var selectedEdge: (float3, float3)?
    
    var planes: [Plane]
    var faces: [BrushFace]
    
    private var selectedFaceIndex: Int?
    
    private var vertexBuffer: MTLBuffer!
    private var vertexBuffer2: MTLBuffer!
    
    init(planes: [Plane])
    {
        self.planes = planes
        self.faces = planes.indices.map { BrushFace(planeIndex: $0) }
    }
    
    init(origin: float3, size: float3)
    {
        planes = [
            Plane(normal: [ 0,  0, -1], distance: 1),
            Plane(normal: [ 0,  0,  1], distance: 1),
            Plane(normal: [ 1,  0,  0], distance: 1),
            Plane(normal: [-1,  0,  0], distance: 1),
            Plane(normal: [ 0,  1,  0], distance: 1),
            Plane(normal: [ 0, -1,  0], distance: 1)
        ]
        
        faces = planes.indices.map { BrushFace(planeIndex: $0) }
        
        let position = origin + size * 0.5
        updatePlanes(position: position, scale: size)
        
        updateWinding()
        setupRenderData()
    }
    
    func setupRenderData()
    {
        let length = MemoryLayout<Vertex>.stride * 128
        vertexBuffer = Engine.device.makeBuffer(length: length)
        vertexBuffer2 = Engine.device.makeBuffer(length: length)
    }
    
    private func updatePlanes(position: float3, scale: float3)
    {
        let halfExtents = scale * 0.5
        
        for i in planes.indices
        {
            let normal = planes[i].normal
            let halfDimention = normal * halfExtents
            let point = position + halfDimention
            
            planes[i].distance = dot(point, normal)
        }
    }
    
    func updateWinding()
    {
        faces.forEach {
            $0.update(from: planes)
        }
    }
    
    func selectFace(by ray: Ray)
    {
    }
    
    func selectEdge(by ray: Ray)
    {
    }
    
    func setWorld(position: float3)
    {
    }
    
    func setSelectedFace(position: float3)
    {
    }
    
    func setSelectedEdge(position: float3)
    {
        
    }
    
    func clip(with other: PlainBrush)
    {
        for face in faces
        {
            face.clip(with: other)
        }
    }
    
    func render(with renderer: ForwardRenderer)
    {
        do
        {
            var renderItem = RenderItem(technique: .brush)
            
            renderItem.cullMode = isRoom ? .front : .back
            renderItem.texture = TextureManager.shared.devTexture
            renderItem.isSupportLineMode = false
            
            var vertices: [Vertex] = []
            
            for face in faces
            {
                let normal = planes[face.planeIndex].normal
                let color = face.planeIndex == selectedFaceIndex ? float4(1, 0, 0, 1) : float4(1, 1, 1, 1)
                
                guard face.points.count > 2 else { continue }
                
                for poly in face.polys
                {
                    guard poly.points.count > 3 else { continue }
                    
                    vertices.append(contentsOf: [
                        Vertex(pos: poly.points[0], nor: normal, clr: color, uv: poly.uvs[0]),
                        Vertex(pos: poly.points[1], nor: normal, clr: color, uv: poly.uvs[1]),
                        Vertex(pos: poly.points[2], nor: normal, clr: color, uv: poly.uvs[2]),
                        Vertex(pos: poly.points[3], nor: normal, clr: color, uv: poly.uvs[3]),
                        Vertex(pos: poly.points[0], nor: normal, clr: color, uv: poly.uvs[0]),
                        Vertex(pos: poly.points[2], nor: normal, clr: color, uv: poly.uvs[2])
                    ])
                }
            }
            
            vertexBuffer.contents().copyMemory(from: vertices, byteCount: MemoryLayout<Vertex>.stride * vertices.count)
            
            renderItem.vertexBuffer = vertexBuffer
            renderItem.numVertices = vertices.count
            renderItem.allowedViews = [.perspective]
            
            renderer.add(item: renderItem)
        }
        
        do
        {
            var renderItem = RenderItem(technique: .brush)
            renderItem.allowedViews = [.top, .back, .right]
            
            var vertices: [Vertex] = []
            
            let color = isSelected ? float4(1, 0, 0, 1) : float4(1, 1, 1, 1)
            
            for face in faces
            {
                let normal = planes[face.planeIndex].normal
                
                guard face.points.count > 2 else { continue }
                
                for i in face.points.indices
                {
                    let p1 = face.points[i]
                    let p2 = face.points[(i + 1) % face.points.count]
                    
                    vertices.append(contentsOf: [
                        Vertex(pos: p1, nor: normal, clr: color),
                        Vertex(pos: p2, nor: normal, clr: color)
                    ])
                }
            }
            
            vertexBuffer2.contents().copyMemory(from: vertices, byteCount: MemoryLayout<Vertex>.stride * vertices.count)
            
            renderItem.primitiveType = .line
            renderItem.vertexBuffer = vertexBuffer2
            renderItem.numVertices = vertices.count
            
            renderer.add(item: renderItem)
        }
    }
}

private struct Vertex
{
    var pos: float3 = .zero
    var nor: float3 = .zero
    var clr: float4 = .one
    var uv: float2 = .zero
    
//    init(_ x: Float, _ y: Float, _ z: Float, _ u: Float, _ v: Float)
//    {
//        self.pos = float3(x, y, z)
//        self.uv = float2(u, v)
//    }
}

private struct BasicVertex
{
    let pos: float3
    let uv: float2 = .zero
}

// Got from GTKRadiant matlib
private func intersect(ray: Ray, point: float3, epsilon: Float, divergence: Float) -> Float
{
    var displacement = float3()
    var depth: Float = 0

    // calc displacement of test point from ray origin
    displacement = point - ray.origin
    
    // calc length of displacement vector along ray direction
    depth = dot(displacement, ray.direction)
    
    if depth < 0.0 {
        return .greatestFiniteMagnitude
    }
    
    // calc position of closest point on ray to test point
    displacement = ray.origin + ray.direction * depth
    
    // calc displacement of test point from closest point
    displacement = point - displacement
    
    // calc length of displacement, subtract depth-dependant epsilon
    if length(displacement) - (epsilon + ( depth * divergence )) > 0 {
        return .greatestFiniteMagnitude
    }
    
    return depth
}
