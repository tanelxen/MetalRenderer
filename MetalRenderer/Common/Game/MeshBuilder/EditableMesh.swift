//
//  EditableMesh.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.05.2024.
//

import Metal
import simd

private let MAX_VERTS: Int = 1024

final class EditableMesh: EditableObject
{
    var isSelected = false {
        didSet {
            selectedFace = nil
            selectedEdge = nil
        }
    }
    
    var selectedFacePoint: float3? {
        return selectedFace?.center
    }
    
    var selectedFaceAxis: float3? {
        guard let face = selectedFace else { return nil }
        return abs(face.plane.normal)
    }
    
    var selectedEdgePoint: float3? {
        return selectedEdge?.center
    }
    
    var selectedEdgeAxis: float3? {
        guard let edge = selectedEdge else { return nil }
        return abs(edge.face.plane.normal)
    }
    
    var worldPosition: float3 {
        faces.first?.verts.first?.position ?? .zero
    }
    
    var vertices: [float3] {
        faces.flatMap { $0.verts.map { $0.position } }
    }
    
    var edges: [HalfEdge] {
        faces.flatMap { $0.edges }
    }
    
    var faces: [Face] = []
    
    var isRoom = false {
        didSet {
            faces.forEach({
                $0.plane.normal = -$0.plane.normal
            })
            
            recalculateUV()
        }
    }
    
    var selectedFace: Face?
    var selectedEdge: HalfEdge?
    
    private var vertexBuffer: MTLBuffer!
    
    init(faces: [Face])
    {
        self.faces = faces
    }
    
    init(origin: float3, size: float3)
    {
        populateFaces(origin: origin, size: size)
        setupRenderData()
    }
    
    init(_ other: EditableMesh)
    {
        faces = other.faces.map {
            let face = Face($0.name)
            
            face.verts = $0.verts.map {
                Vert($0.position)
            }
            
            return face
        }
        
        recalculate()
        setupRenderData()
    }
    
    func setupRenderData()
    {
        let length = MemoryLayout<Vertex>.stride * MAX_VERTS
        vertexBuffer = Engine.device.makeBuffer(length: length)
    }
    
    func selectFace(by ray: Ray)
    {
        selectedFace = nil
        
        for face in faces
        {
            if intersect(ray: ray, face: face)
            {
                selectedFace = face
                break
            }
        }
    }
    
    func selectEdge(by ray: Ray)
    {
        var bestd: Float = 4
        var beste: HalfEdge?
        
        for face in faces
        {
            guard intersect(ray: ray, face: face)
            else {
                continue
            }
            
            for edge in face.edges
            {
                let p1 = edge.vert.position
                let p2 = edge.next.vert.position
                
                let d = closestDistance(ray: ray, lineStart: p1, lineEnd: p2)
                
                if d < bestd
                {
                    bestd = d
                    beste = edge
                }
            }
        }
        
        selectedEdge = beste
    }
    
    func setSelectedFace(position: float3)
    {
        guard let face = selectedFace else { return }
        
        let delta = position - face.center
        
        guard length(delta) > 0 else { return }
        
        for vert in face.verts
        {
            let iter = VertexEdgeIterator(vert)
            
            while let twin = iter.next()?.vert
            {
                twin.position += delta
            }
        }
        
        face.plane.distance = dot(face.plane.normal, face.center)
        
        recalculateUV()
    }
    
    func removeSelectedFace()
    {
        faces.removeAll(where: { $0 === selectedFace })
        selectedFace = nil
        recalculate()
    }
    
    func setSelectedEdge(position: float3)
    {
        guard let edge = selectedEdge else { return }
        
        let delta = position - edge.center
        
        guard length(delta) > 0 else { return }
        
        for vert in [edge.vert!, edge.next.vert!]
        {
            let iter = VertexEdgeIterator(vert)
            
            while let twin = iter.next()?.vert
            {
                twin.position += delta
            }
        }
        
        recalculateUV()
    }
    
    func setWorld(position: float3)
    {
        let delta = position - worldPosition
        guard length(delta) > 1 else { return }
        
        for face in faces
        {
            for vert in face.verts
            {
                vert.position += delta
            }
        }
    }
    
    func extrudeSelectedFace(to distance: Float)
    {
        guard let face = selectedFace else { return }
        
        guard distance > 0 else { return }
        
        let delta = face.plane.normal * distance
        
        for vert in face.verts
        {
            vert.position += delta
        }
        
        for edge in face.edges
        {
            let newFace = Face(edge.pair.face.name + "-ext-by-" + edge.pair.name)
            
            newFace.plane = edge.pair.face.plane
            newFace.verts = [
                Vert(edge.pair.vert.position),
                Vert(edge.next.vert.position),
                Vert(edge.vert.position),
                Vert(edge.pair.next.vert.position)
            ]
            faces.append(newFace)
        }
        
        recalculate()
    }
    
    func recalculateUV()
    {
        for face in faces
        {
            face.updateUVs()
        }
    }
    
    func render(with renderer: ForwardRenderer)
    {
        var renderItem = RenderItem(technique: .brush)
        
        renderItem.cullMode = isRoom ? .front : .back
        renderItem.texture = TextureManager.shared.devTexture
        renderItem.isSupportLineMode = true
        
        // wireframe of selected meshes we draw separates with MeshUtilityRenderer
        if isSelected
        {
            renderItem.allowedViews = [.perspective]
        }
        
        var vertices: [Vertex] = []
        
        for face in faces
        {
            guard face.verts.count > 2 else { continue }
            
            let normal = face.plane.normal
            let color = face === selectedFace ? float4(1, 0, 0, 1) : float4(1, 1, 1, 1)
            
            let verts = face.triangles.map {
                Vertex(pos: $0.position, nor: normal, clr: color, uv: $0.uv)
            }

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
    }
}

extension EditableMesh
{
    func populateFaces(origin: float3, size: float3)
    {
        let back = Face("back")
        back.verts = [
            Vert([0, 0, 0]),
            Vert([1, 0, 0]),
            Vert([1, 1, 0]),
            Vert([0, 1, 0])
        ]
        faces.append(back)
        
        let front = Face("front")
        front.verts = [
            Vert([1, 0, 1]),
            Vert([0, 0, 1]),
            Vert([0, 1, 1]),
            Vert([1, 1, 1])
        ]
        faces.append(front)
        
        let top = Face("top")
        top.verts = [
            Vert([0, 1, 0]),
            Vert([1, 1, 0]),
            Vert([1, 1, 1]),
            Vert([0, 1, 1])
        ]
        faces.append(top)
        
        let bottom = Face("bottom")
        bottom.verts = [
            Vert([1, 0, 0]),
            Vert([0, 0, 0]),
            Vert([0, 0, 1]),
            Vert([1, 0, 1])
        ]
        faces.append(bottom)
        
        let right = Face("right")
        right.verts = [
            Vert([1, 0, 0]),
            Vert([1, 0, 1]),
            Vert([1, 1, 1]),
            Vert([1, 1, 0])
        ]
        faces.append(right)
        
        let left = Face("left")
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
        }
        
        recalculate()
    }
    
    func recalculate()
    {
        for face in faces
        {
            let v1 = face.verts[1].position - face.verts[0].position
            let v2 = face.verts[2].position - face.verts[0].position
            let normal = normalize(cross(v2, v1))
            
            let distance = dot(normal, face.verts[0].position)
            face.plane = Plane(normal: normal, distance: distance)
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
            
            face.updateUVs()
            face.triangulate()
        }
    }
    
    func populateEdges(for face: Face)
    {
        for i in face.verts.indices
        {
            let edge = HalfEdge("\(i)")
            edge.vert = face.verts[i]
            edge.face = face
            
            edge.prev = face.edges.last
            face.edges.last?.next = edge
            
            face.verts[i].edge = edge
            
            face.edges.append(edge)
        }
        
        face.edges.last?.next = face.edges.first
        face.edges.first?.prev = face.edges.last
    }
    
    func setupPairs(for edge: HalfEdge)
    {
        for face in faces
        {
            guard face !== edge.face else { continue }
            
            for other in face.edges
            {
                let dist1 = length(edge.vert.position - other.next.vert.position)
                let dist2 = length(edge.next.vert.position - other.vert.position)
                
                if dist1 < 0.1 && dist2 < 0.1
                {
                    edge.pair = other
                }
            }
        }
    }
}

private let baseaxis: [float3] = [
    [ 0,-1, 0], [-1, 0, 0], [0, 0,-1], // floor
    [ 0, 1, 0], [ 1, 0, 0], [0, 0,-1], // ceiling
    [-1, 0, 0], [ 0, 0,-1], [0,-1, 0], // west wall
    [ 1, 0, 0], [ 0, 0, 1], [0,-1, 0], // east wall
    [ 0, 0, 1], [-1, 0, 0], [0,-1, 0], // south wall
    [ 0, 0,-1], [ 1, 0, 0], [0,-1, 0]  // north wall
]

private extension Face
{
    func textureAxisFromPlane(normal: float3) -> (xv: float3, yv: float3)
    {
        var bestaxis: Int = 0
        var best: Float = 0

        for i in 0 ..< 6
        {
            let dot = dot(normal, baseaxis[i*3])
            
            if dot > best
            {
                best = dot
                bestaxis = i
            }
        }
        
        let xv = baseaxis[bestaxis*3+1]
        let yv = baseaxis[bestaxis*3+2]
        
        return (xv, yv)
    }
    
    func updateUVs()
    {
        let (xv, yv) = textureAxisFromPlane(normal: plane.normal)
        
        let matrix = float4x4(
            float4(xv.x, yv.x, plane.normal.x, 0),
            float4(xv.y, yv.y, plane.normal.y, 0),
            float4(xv.z, yv.z, plane.normal.z, 0),
            float4(0, 0, -plane.distance, 1)
        )
        
        for i in verts.indices
        {
            var projected = matrix * float4(verts[i].position, 1)
            projected = projected / projected.w
            projected = projected / 64
            
            verts[i].uv.x = projected.x
            verts[i].uv.y = projected.y
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

// Find closest distance between ray and line
func closestDistance(ray: Ray, lineStart: float3, lineEnd: float3) -> Float
{
    let EPS: Float = 0.1
    
    let p1 = ray.origin
    let p21 = ray.direction
    
    let p3 = lineStart
    let p4 = lineEnd
    
    let p13 = p1 - p3
    let p43 = p4 - p3
    
    let d1343 = dot(p13, p43)
    let d4321 = dot(p43, p21)
    let d1321 = dot(p13, p21)
    let d4343 = dot(p43, p43)
    let d2121 = dot(p21, p21)
    
    let denom = d2121 * d4343 - d4321 * d4321
    
    if abs(denom) < EPS {
        return .greatestFiniteMagnitude
    }
    
    let numer = d1343 * d4321 - d1321 * d4343

    let mua = numer / denom
    let mub = (d1343 + d4321 * mua) / d4343
    
    let pa = p1 + mua * p21
    let pb = p3 + mub * p43
    
    // check that find point lay on the line
    if mub < 0 || mub > 1 {
        return .greatestFiniteMagnitude
    }
    
    return length(pa - pb)
}

func intersect(ray: Ray, face: Face) -> Bool
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
    
    let v0 = face.verts[0].position
    let v1 = face.verts[1].position
    let v2 = face.verts[2].position
    let v3 = face.verts[3].position
    
    let e0 = cross(v1 - v0, p - v0)
    let e1 = cross(v2 - v1, p - v1)
    let e2 = cross(v3 - v2, p - v2)
    let e3 = cross(v0 - v3, p - v3)
    
    return dot(e0, n) < 0 && dot(e1, n) < 0 && dot(e2, n) < 0 && dot(e3, n) < 0
}
