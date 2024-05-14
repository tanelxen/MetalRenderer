//
//  EditableMesh.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.05.2024.
//

import Metal
import simd

class Vert
{
    var position: float3
    var edge: HalfEdge!
    
    init(_ pos: float3)
    {
        position = pos
    }
}

class HalfEdge
{
    var name: String
    
    var vert: Vert!
    var face: Face!
    
    var pair: HalfEdge!
    var next: HalfEdge!
    
    init(_ name: String = "")
    {
        self.name = name
    }
}

class Face
{
    var name: String
    
    var edges: [HalfEdge] = []
    var verts: [Vert] = []
    
    var normal: float3 = .zero
    var plane: Plane!
    
    var center: float3 {
        let points = verts.map { $0.position }
        return points.reduce(.zero, +) / Float(points.count)
    }
    
    init(_ name: String = "")
    {
        self.name = name
    }
}

class EditableMesh
{
    var isSelected = false
    
    var selectedFacePoint: float3? {
        return selectedFace?.center
    }
    
    var selectedFaceAxis: float3? {
        guard let face = selectedFace else { return nil }
        return abs(face.plane.normal)
    }
    
    private var faces: [Face] = []
    
    private var selectedFace: Face?
    
    init(origin: float3, size: float3)
    {
        populateFaces(origin: origin, size: size)
    }
    
    func selectFace(by ray: Ray)
    {
        selectedFace = nil
        
        var start_frac: Float = -1.0
        var end_frac: Float = 1.0
        var closest: Face?
        
        let SURF_CLIP_EPSILON: Float = 0.125
        
        var startout = false
        
        let start = ray.origin
        let end = ray.origin + ray.direction * 1024
        
        for face in faces
        {
            let dist = face.plane.distance

            let start_distance = dot(start, face.plane.normal) - dist
            let end_distance = dot(end, face.plane.normal) - dist
            
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
                    closest = face
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
            selectedFace = closest
        }
    }
    
    func selectEdge(by ray: Ray) { }
    
    func setSelectedFace(position: float3)
    {
        guard let face = selectedFace else { return }
        
        let delta = (position - face.center) * abs(face.plane.normal)
        
        guard length(delta) > 0 else { return }
        
        for edge in face.edges
        {
            edge.vert.position += delta
            
            edge.pair.vert.position += delta
            edge.pair.next.vert.position += delta
        }
        
        let distance = dot(face.normal, face.verts[0].position)
        face.plane = Plane(normal: face.normal, distance: distance)
    }
    
    func render(with encoder: MTLRenderCommandEncoder, to renderer: ForwardRenderer)
    {
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
            let normal = face.normal
            let color = face === selectedFace ? float4(1, 0, 0, 1) : float4(1, 1, 0, 1)

            let verts = [
                Vertex(pos: face.verts[0].position, nor: normal, clr: color),
                Vertex(pos: face.verts[1].position, nor: normal, clr: color),
                Vertex(pos: face.verts[2].position, nor: normal, clr: color),
                Vertex(pos: face.verts[3].position, nor: normal, clr: color),
                Vertex(pos: face.verts[0].position, nor: normal, clr: color),
                Vertex(pos: face.verts[2].position, nor: normal, clr: color)
            ]

            vertices.append(contentsOf: verts)
        }
        
        encoder.setVertexBytes(vertices, length: MemoryLayout<Vertex>.stride * vertices.count, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
    }
}

private extension EditableMesh
{
    func populateFaces(origin: float3, size: float3)
    {
        let back = Face("back")
        back.normal = [0, 0, -1]
        back.verts = [
            Vert([0, 0, 0]),
            Vert([1, 0, 0]),
            Vert([1, 1, 0]),
            Vert([0, 1, 0])
        ]
        faces.append(back)
        
        let front = Face("front")
        front.normal = [0, 0, 1]
        front.verts = [
            Vert([1, 0, 1]),
            Vert([0, 0, 1]),
            Vert([0, 1, 1]),
            Vert([1, 1, 1])
        ]
        faces.append(front)
        
        let top = Face("top")
        top.normal = [0, 1, 0]
        top.verts = [
            Vert([0, 1, 0]),
            Vert([1, 1, 0]),
            Vert([1, 1, 1]),
            Vert([0, 1, 1])
        ]
        faces.append(top)
        
        let bottom = Face("bottom")
        bottom.normal = [0, -1, 0]
        bottom.verts = [
            Vert([1, 0, 0]),
            Vert([0, 0, 0]),
            Vert([0, 0, 1]),
            Vert([1, 0, 1])
        ]
        faces.append(bottom)
        
        let right = Face("right")
        right.normal = [1, 0, 0]
        right.verts = [
            Vert([1, 0, 0]),
            Vert([1, 0, 1]),
            Vert([1, 1, 1]),
            Vert([1, 1, 0])
        ]
        faces.append(right)
        
        let left = Face("left")
        left.normal = [-1, 0, 0]
        left.verts = [
            Vert([0, 0, 1]),
            Vert([0, 0, 0]),
            Vert([0, 1, 0]),
            Vert([0, 1, 1])
        ]
        faces.append(left)
        
        for face in faces
        {
            for vert in face.verts
            {
                vert.position = origin + vert.position * size
            }
            
            let distance = dot(face.normal, face.verts[0].position)
            face.plane = Plane(normal: face.normal, distance: distance)
        }
        
        for face in faces
        {
            populateEdges(for: face)
        }
        
        for face in faces
        {
            for edge in face.edges
            {
                setupPairs(for: edge)
            }
        }
    }
    
    func populateEdges(for face: Face)
    {
        let edge0 = HalfEdge("0")
        let edge1 = HalfEdge("1")
        let edge2 = HalfEdge("2")
        let edge3 = HalfEdge("3")
        
        edge0.vert = face.verts[0]
        edge0.face = face
        edge0.next = edge1
        
        edge1.vert = face.verts[1]
        edge1.face = face
        edge1.next = edge2
        
        edge2.vert = face.verts[2]
        edge2.face = face
        edge2.next = edge3
        
        edge3.vert = face.verts[3]
        edge3.face = face
        edge3.next = edge0
        
        face.verts[0].edge = edge0
        face.verts[1].edge = edge1
        face.verts[2].edge = edge2
        face.verts[3].edge = edge3
        
        face.edges = [
            edge0, edge1, edge2, edge3
        ]
    }
    
    func setupPairs(for edge: HalfEdge)
    {
        for face in faces
        {
            guard face !== edge.face else { continue }
            
            for other in face.edges
            {
                if edge.vert.position == other.next.vert.position && edge.next.vert.position == other.vert.position
                {
                    edge.pair = other
                }
            }
        }
    }
}

private struct Vertex
{
    var pos: float3 = .zero
    var nor: float3 = .zero
    var clr: float4 = .one
    var uv: float2 = .zero
}
