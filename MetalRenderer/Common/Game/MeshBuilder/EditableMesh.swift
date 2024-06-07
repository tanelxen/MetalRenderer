//
//  EditableMesh.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.05.2024.
//

import Metal
import simd

//private let MAX_VERTS: Int = 3

final class EditableMesh: EditableObject
{
    var transform: Transform = Transform()
    
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
    
    var texture: String = ""
    
    var center: float3 = .zero
    
    var selectedFace: Face?
    var selectedEdge: HalfEdge?
    
    private var vertexBuffer: MTLBuffer!
    
    init(faces: [Face])
    {
        self.faces = faces
    }
    
    init(origin: float3, size: float3)
    {
        populateCubeFaces(origin: origin, size: size)
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
        let length = MemoryLayout<Vertex>.stride * 36
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
//            let iter = VertexEdgeIterator(vert)
//
//            while let twin = iter.next()?.vert
//            {
//                twin.position += delta
//            }
            
            vert.position += delta
            
            for twin in vert.neighbours
            {
                twin.position += delta
            }
        }
        
        face.plane.distance = dot(face.plane.normal, face.center)
        
        for edge in face.edges
        {
            edge.pair?.face.updateUVs()
        }
    }
    
    func removeSelectedFace()
    {
        faces.removeAll(where: { $0 === selectedFace })
        
        selectedFace?.verts.forEach {
            for other in $0.neighbours {
                other.neighbours.remove($0)
            }
        }
        
        selectedFace = nil
    }
    
    func setSelectedEdge(position: float3)
    {
        guard let edge = selectedEdge else { return }
        
        let delta = position - edge.center
        
        guard length(delta) > 0 else { return }
        
        for vert in [edge.vert!, edge.next.vert!]
        {
            vert.position += delta
            
            for twin in vert.neighbours
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
        
        // Make face copy with offset along normal
        
        let newFace = Face(face.name + "-extruded")
        
        for vert in face.verts
        {
            newFace.verts.append(
                Vert(vert.position + delta)
            )
        }
        
        faces.append(newFace)
        
        // Fill the gaps
        
        for edge in face.edges
        {
            let newFace = Face("bridge" + face.name + "-to-extruded" + "-by-edge-" + edge.name)
            
            newFace.verts = [
                Vert(edge.vert.position),
                Vert(edge.next.vert.position),
                Vert(edge.next.vert.position + delta),
                Vert(edge.vert.position + delta)
            ]
            faces.append(newFace)
        }
        
        // Remove original face
        faces.removeAll(where: { $0 === face })
        selectedFace = newFace
        
        recalculate()
    }
    
    func splitSelectedFace()
    {
        guard let face = selectedFace else { return }
        
        let p1 = face.edges[0].center
        let p2 = face.edges[2].center
//        let dir = normalize(p2 - p1)
//
//        var splitterNormal = cross(face.plane.normal, dir)
//        splitterNormal = normalize(splitterNormal)
        
        let newFace1 = Face(face.name + "-splitted-left")
        newFace1.verts = [
            Vert(face.verts[0].position),
            Vert(p1),
            Vert(p2),
            Vert(face.verts[3].position)
        ]
        faces.append(newFace1)
        
        let newFace2 = Face(face.name + "-splitted-right")
        newFace2.verts = [
            Vert(p1),
            Vert(face.verts[1].position),
            Vert(face.verts[2].position),
            Vert(p2)
        ]
        faces.append(newFace2)
        
        // split bottom edge
        if let pair = face.edges[0].pair
        {
            pair.face.verts.insert(Vert(p1), at: 3)
        }
        
        // split top edge
        if let pair = face.edges[2].pair
        {
            pair.face.verts.insert(Vert(p2), at: 3)
        }
        
        // Remove original face
        faces.removeAll(where: { $0 === face })
        selectedFace = nil
        
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
        renderItem.texture = EditorLayer.current.texturesDict[texture]?.texture ?? TextureManager.shared.devTexture
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
        
        vertexBuffer.contents().copyMemory(from: vertices, byteCount: MemoryLayout<Vertex>.stride * vertices.count)
    
        renderItem.vertexBuffer = vertexBuffer
        renderItem.numVertices = vertices.count
        
        renderer.add(item: renderItem)
    }
}

extension EditableMesh
{
    func populateCubeFaces(origin: float3, size: float3)
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
            
            for vert in face.verts
            {
                setupNeighbours(for: vert)
            }
            
            if face.isGhost
            {
                face.triangles.removeAll()
            }
            else
            {
                face.updateUVs()
                face.triangulate()
            }
        }
        
        center = faces.map({ $0.center }).reduce(.zero, +) / Float(faces.count)
    }
    
    func populateEdges(for face: Face)
    {
        face.edges.removeAll(keepingCapacity: true)
        
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
    
    func setupNeighbours(for vert: Vert)
    {
        for face in faces
        {
            guard face !== vert.edge.face else { continue }
            
            for other in face.verts
            {
                if vert.isClose(to: other) {
                    vert.neighbours.insert(other)
                }
            }
            
            // Vertex can't have more than 5 neighbours
            if vert.neighbours.count == 5 {
                break
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

extension Face
{
    private func textureAxisFromPlane(normal: float3) -> (xv: float3, yv: float3)
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
            
            var uv = float2(projected.x, projected.y)
            
            uv += uvOffset
            uv *= uvScale
            uv /= texSize
            
            verts[i].uv = uv
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
    
    var inside = true
    
    for edge in face.edges
    {
        let v0 = edge.vert.position
        let v1 = edge.next.vert.position
        
        let e = cross(v1 - v0, p - v0)
        
        inside = inside && dot(e, n) < 0
    }
    
    return inside
}

func intersectDistance(ray: Ray, face: Face) -> Float
{
    let n = face.plane.normal

    if dot(n, ray.direction) > 0 {
        return .greatestFiniteMagnitude
    }
    
    let d = ray.origin - face.center
    let t = -dot(n, d) / dot(n, ray.direction)
    
    if t < 0 {
        return .greatestFiniteMagnitude
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
    
    guard dot(e0, n) < 0 && dot(e1, n) < 0 && dot(e2, n) < 0 && dot(e3, n) < 0
    else {
        return .greatestFiniteMagnitude
    }
    
    return t
}

// Return distance to closest intersection point
func intersect(ray: Ray, mesh: EditableMesh) -> Float
{
    var bestd: Float = .greatestFiniteMagnitude
    
    for face in mesh.faces
    {
        let d = intersectDistance(ray: ray, face: face)
        
        if d < bestd
        {
            bestd = d
        }
    }
    
    return bestd
}
