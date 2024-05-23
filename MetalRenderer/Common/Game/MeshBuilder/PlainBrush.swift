//
//  WorldBrush.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 20.04.2024.
//

import Metal
import simd

private let MAX_VERTS: Int = 36

final class PlainBrush: EditableObject
{
    var isSelected = false {
        didSet {
            selectedFaceIndex = nil
        }
    }
    
    var worldPosition: float3 {
        faces.first?.points.first ?? .zero
    }
    
    var selectedFacePoint: float3? {
        guard let index = selectedFaceIndex else { return nil }
        return faces[index].center
    }
    
    var selectedFaceAxis: float3? {
        guard let index = selectedFaceIndex else { return nil }
        return abs(planes[index].normal)
    }
    
    var selectedEdgePoint: float3? {
        return nil
    }
    
    var selectedEdgeAxis: float3? {
        return nil
    }
    
    var isRoom = false
    
    var selectedPlane: Plane? {
        guard let index = selectedFaceIndex else { return nil }
        return planes[index]
    }
    
    var selectedEdge: (float3, float3)?
    
    var planes: [Plane]
    var faces: [BrushFace]
    
    private var selectedFaceIndex: Int?
    
    private var vertexBuffer: MTLBuffer!
    private var vertexBuffer2: MTLBuffer!
    
    required init(origin: float3, size: float3)
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
        
        faces.forEach {
            $0.update(from: planes)
        }
        
        let length = MemoryLayout<Vertex>.stride * MAX_VERTS
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
    
    func selectEdge(by ray: Ray)
    {
        var bestd: Float = .greatestFiniteMagnitude
        var besti = -1
        var bestj = -1
        
        for i in faces.indices
        {
            for j in faces[i].points.indices
            {
                let p1 = faces[i].points[j]
                let p2 = faces[i].points[(j + 1) % 4]
                let mid = (p1 + p2) * 0.5
                
                let d = intersect(ray: ray, point: mid, epsilon: 8, divergence: 0.01)
                
                if d < bestd
                {
                    bestd = d
                    besti = i
                    bestj = j
                }
            }
        }
        
        print("face: \(besti) vertex: \(bestj)")
        
        if besti != -1 && bestj != -1
        {
            selectedEdge = (
                faces[besti].points[bestj],
                faces[besti].points[(bestj + 1) % 4]
            )
            
            print("p1: \(selectedEdge!.0) p2: \(selectedEdge!.1)")
        }
    }
    
    func setWorld(position: float3)
    {
        let delta = position - worldPosition
        guard length(delta) > 1 else { return }
        
        for face in faces
        {
            for i in face.points.indices
            {
                face.points[i] += delta
            }
        }
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
        
        faces.forEach {
            $0.update(from: planes)
        }
    }
    
//    func setSelectedPlane(distance value: Float)
//    {
//        guard let index = selectedFaceIndex else { return }
//        planes[index].distance = value
//        
//        faces.forEach {
//            $0.update(from: planes)
//        }
//    }
    
    func setSelectedEdge(position: float3)
    {
        
    }
    
    func clip(with other: PlainBrush)
    {
        let inverted = other.planes.map { Plane(normal: -$0.normal, distance: -$0.distance) }
        
        for face in faces
        {
            face.clip(by: inverted)
            face.updateUVs(with: planes[face.planeIndex])
        }
    }
    
    func clip(with plane: Plane)
    {
        for face in faces
        {
            face.windingClip(by: plane)
            face.updateUVs(with: planes[face.planeIndex])
        }
    }
    
    func render(with renderer: ForwardRenderer)
    {
        var renderItem = RenderItem(technique: .brush)
        
        renderItem.cullMode = isRoom ? .front : .back
        renderItem.texture = TextureManager.shared.devTexture
        renderItem.isSupportLineMode = true
        
        var vertices: [Vertex] = []
        
        for face in faces
        {
            let normal = planes[face.planeIndex].normal
            let color = face.planeIndex == selectedFaceIndex ? float4(1, 0, 0, 1) : float4(1, 1, 1, 1)
            
            guard face.points.count > 2 else { continue }

            let verts = [
                Vertex(pos: face.points[0], nor: normal, clr: color, uv: face.uvs[0]),
                Vertex(pos: face.points[1], nor: normal, clr: color, uv: face.uvs[1]),
                Vertex(pos: face.points[2], nor: normal, clr: color, uv: face.uvs[2]),
                Vertex(pos: face.points[3], nor: normal, clr: color, uv: face.uvs[3]),
                Vertex(pos: face.points[0], nor: normal, clr: color, uv: face.uvs[0]),
                Vertex(pos: face.points[2], nor: normal, clr: color, uv: face.uvs[2])
            ]

            vertices.append(contentsOf: verts)
        }
        
        var pointer = vertexBuffer.contents().bindMemory(to: Vertex.self, capacity: MAX_VERTS)
        
        for vertex in vertices
        {
            pointer.pointee = vertex
            pointer = pointer.advanced(by: 1)
        }
    
        renderItem.vertexBuffer = vertexBuffer
        renderItem.numVertices = vertices.count
        
        renderer.add(item: renderItem)
        
        if isSelected
        {
            var renderItem = RenderItem(technique: .brush)
            
            renderItem.cullMode = .none
            renderItem.isSupportLineMode = true
            renderItem.primitiveType = .point
            
            var vertices: [Vertex] = []
            
            for face in faces
            {
                let vertClr = float4(1, 1, 1, 1)
                let faceClr = face.isHighlighted ? float4(0, 1, 0, 1) : float4(1, 0, 1, 1)
                let edgeClr = float4(1, 0, 0, 1)
                
                guard face.points.count > 2 else { continue }

                let verts = [
                    Vertex(pos: face.points[0], clr: vertClr),
                    Vertex(pos: face.points[1], clr: vertClr),
                    Vertex(pos: face.points[2], clr: vertClr),
                    Vertex(pos: face.points[3], clr: vertClr),
                    
                    Vertex(pos: face.center, clr: faceClr),
                    
                    Vertex(pos: (face.points[0] + face.points[1]) * 0.5, clr: edgeClr),
                    Vertex(pos: (face.points[1] + face.points[2]) * 0.5, clr: edgeClr),
                    Vertex(pos: (face.points[2] + face.points[3]) * 0.5, clr: edgeClr),
                    Vertex(pos: (face.points[3] + face.points[0]) * 0.5, clr: edgeClr)
                ]

                vertices.append(contentsOf: verts)
            }
            
            var pointer = vertexBuffer2.contents().bindMemory(to: Vertex.self, capacity: MAX_VERTS)
            
            for vertex in vertices
            {
                pointer.pointee = vertex
                pointer = pointer.advanced(by: 1)
            }
        
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
