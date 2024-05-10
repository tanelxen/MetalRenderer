//
//  WorldBrush.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 20.04.2024.
//

import Metal
import simd

final class WorldBrush
{
    var transform = Transform()
    
    var origin: float3 {
        transform.position
    }
    
    var size: float3 {
        return transform.scale
    }
    
    private var planes: [Plane]
    private var faces: [BrushFace]
    
    private var selectedFaceIndex: Int?
    
    var isSelected = false {
        didSet {
            selectedFaceIndex = nil
        }
    }
    
    var selectedFacePoint: float3? {
        guard let index = selectedFaceIndex else { return nil }
        return faces[index].center
    }
    
    var selectedFaceAxis: float3? {
        guard let index = selectedFaceIndex else { return nil }
        return abs(planes[index].normal)
    }
    
    private let box = MTKGeometry(.box)
    private let facePoint = MTKGeometry(.box, extents: [2, 2, 2])
    
    init(origin: float3, size: float3)
    {
        transform.position = origin + size * 0.5
        transform.scale = size
        
        planes = [
            Plane(normal: [ 0,  0,  1], distance: 1),
            Plane(normal: [ 0,  0, -1], distance: 1),
            Plane(normal: [-1,  0,  0], distance: 1),
            Plane(normal: [ 1,  0,  0], distance: 1),
            Plane(normal: [ 0, -1,  0], distance: 1),
            Plane(normal: [ 0,  1,  0], distance: 1)
        ]
        
        faces = planes.indices.map { BrushFace(planeIndex: $0) }
        
        updatePlanesFromTransform()
        
        faces.forEach {
            $0.update(from: planes)
        }
    }
    
    private func updatePlanesFromTransform()
    {
        let halfExtents = transform.scale * 0.5
        
        for i in planes.indices
        {
            let normal = planes[i].normal
            let halfDimention = normal * halfExtents
            let point = transform.position + halfDimention
            
            planes[i].distance = dot(point, normal)
        }
    }
    
    private func updateTransformFromPlanes()
    {
        let scaleX = planes[3].distance - planes[2].distance
        let scaleY = planes[5].distance - planes[4].distance
        let scaleZ = planes[0].distance - planes[1].distance
        
        let posX = planes[2].distance + scaleX * 0.5
        let posY = planes[4].distance + scaleY * 0.5
        let posZ = planes[1].distance + scaleZ * 0.5
        
        transform.position = [posX, posY, posZ]
        transform.scale = [scaleX, scaleY, scaleZ]
    }
    
    func setSelectedFace(position: float3)
    {
        guard let index = selectedFaceIndex else { return }

        let normal = planes[index].normal
        let value = position * normal
        
        if normal.x != 0 {
            planes[index].distance = value.x
        } else if normal.y != 0 {
            planes[index].distance = value.y
        } else if normal.z != 0 {
            planes[index].distance = value.z
        }
        
//        updateTransformFromPlanes()
        
        faces.forEach {
            $0.update(from: planes)
        }
    }
    
    func setSelectedPlane(distance value: Float)
    {
        guard let index = selectedFaceIndex else { return }
        planes[index].distance = value
        
        faces.forEach {
            $0.update(from: planes)
        }
    }
    
    func selectFace(by ray: Ray)
    {
        selectedFaceIndex = nil
        
        var start_frac: Float = -1.0
        var end_frac: Float = 1.0
        var closest: Int?
        
        let SURF_CLIP_EPSILON: Float = 0.125
        
//        var getout = false
        var startout = false
        
        let start = ray.origin
        let end = ray.origin + ray.direction * 1024
        
        for (i, plane) in planes.enumerated()
        {
            let dist = plane.distance

            let start_distance = dot(start, plane.normal) - dist
            let end_distance = dot(end, plane.normal) - dist
            
            if start_distance > 0 { startout = true }
            
            // endpoint is not in solid
//            if end_distance > 0 { getout = true }
            
            if (start_distance > 0 && (end_distance >= SURF_CLIP_EPSILON || end_distance >= start_distance)) { return }
            if (start_distance <= 0 && end_distance <= 0) { continue }
            
            if start_distance > end_distance
            {
                let frac = (start_distance - SURF_CLIP_EPSILON) / (start_distance - end_distance)
                
                if frac > start_frac
                {
                    start_frac = frac
                    closest = i
                }
            }
            else // line is leaving the brush
            {
                let frac = (start_distance + SURF_CLIP_EPSILON) / (start_distance - end_distance)
                
                end_frac = min(end_frac, frac)
            }
        }
        
        // original point was inside brush
        if !startout { return }
        
        if start_frac < end_frac && start_frac > -1
        {
            selectedFaceIndex = closest
        }
    }
    
    func render(with encoder: MTLRenderCommandEncoder, to renderer: ForwardRenderer)
    {
        transform.updateModelMatrix()
        
        renderer.apply(tehnique: .brush, to: encoder)
        
        let tr = Transform()
        tr.updateModelMatrix()
        
        var modelConstants = ModelConstants()
        modelConstants.color = .one
        modelConstants.modelMatrix = tr.matrix
        encoder.setVertexBytes(&modelConstants, length: MemoryLayout<ModelConstants>.size, index: 2)
        
        var vertices: [Vertex] = []
        
        for face in faces
        {
            let normal = planes[face.planeIndex].normal
            let color = face.planeIndex == selectedFaceIndex ? float4(1, 0, 0, 1) : float4(1, 1, 0, 1)
            
            let verts = [
                Vertex(pos: face.points[0], nor: normal, clr: color),
                Vertex(pos: face.points[1], nor: normal, clr: color),
                Vertex(pos: face.points[2], nor: normal, clr: color),
                Vertex(pos: face.points[0], nor: normal, clr: color),
                Vertex(pos: face.points[2], nor: normal, clr: color),
                Vertex(pos: face.points[3], nor: normal, clr: color)
            ]
            
            vertices.append(contentsOf: verts)
        }
        
        encoder.setVertexBytes(vertices, length: MemoryLayout<Vertex>.stride * vertices.count, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
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
