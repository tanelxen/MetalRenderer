//
//  EditableMesh.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.05.2024.
//

import Metal
import simd

final class EditableMesh: EditableObject
{
    var isSelected = false {
        didSet {
            selectedFace = nil
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
    
    var vertices: [float3] {
        faces.flatMap { $0.verts.map { $0.position } }
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
    
    private var selectedFace: Face?
    private var selectedEdge: HalfEdge?
    
    private var vertexBuffer: MTLBuffer!
    private var vertexBuffer2: MTLBuffer!
    
    private let point = MTKGeometry(.box)
    
    required init(origin: float3, size: float3)
    {
        populateFaces(origin: origin, size: size)
        
        let length = MemoryLayout<Vertex>.stride * 1024
        vertexBuffer = Engine.device.makeBuffer(length: length)
        vertexBuffer2 = Engine.device.makeBuffer(length: length)
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
        var bestd: Float = 8
        var beste: HalfEdge?
        
        for face in faces
        {
            for edge in face.edges
            {
                let p1 = edge.vert.position
                let p2 = edge.next.vert.position
                
                let d = intersect(ray: ray, lineStart: p1, lineEnd: p2)
                
                if d < bestd
                {
                    bestd = d
                    beste = edge
                }
            }
        }
        
        selectedEdge = beste
        
        if let edge = beste
        {
            print("\(edge.face.name).\(edge.name)")
        }
    }
    
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
        
        recalculateUV()
    }
    
    func setSelectedEdge(position: float3)
    {
        guard let edge = selectedEdge else { return }
        
        let delta = position - edge.center
        
        guard length(delta) > 0 else { return }
        
        edge.vert.position += delta
        edge.next.vert.position += delta
        
        edge.pair.vert.position += delta
        edge.pair.next.vert.position += delta
        
        edge.prev.pair.vert.position += delta
        edge.next.pair.next.vert.position += delta
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
            
            newFace.normal = edge.pair.face.normal
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
        
        var vertices: [Vertex] = []
        
        for face in faces
        {
            let normal = face.normal
            let color = face === selectedFace ? float4(1, 0, 0, 1) : float4(1, 1, 1, 1)

            let verts = [
                Vertex(pos: face.verts[0].position, nor: normal, clr: color, uv: face.verts[0].uv),
                Vertex(pos: face.verts[1].position, nor: normal, clr: color, uv: face.verts[1].uv),
                Vertex(pos: face.verts[2].position, nor: normal, clr: color, uv: face.verts[2].uv),
                Vertex(pos: face.verts[3].position, nor: normal, clr: color, uv: face.verts[3].uv),
                Vertex(pos: face.verts[0].position, nor: normal, clr: color, uv: face.verts[0].uv),
                Vertex(pos: face.verts[2].position, nor: normal, clr: color, uv: face.verts[2].uv)
            ]

            vertices.append(contentsOf: verts)
        }
        
        var pointer = vertexBuffer.contents().bindMemory(to: Vertex.self, capacity: 1024)
        
        for vertex in vertices
        {
            pointer.pointee = vertex
            pointer = pointer.advanced(by: 1)
        }
    
        renderItem.vertexBuffer = vertexBuffer
        renderItem.numVertices = vertices.count
        
        renderer.add(item: renderItem)
        
//        if let edge = selectedEdge
//        {
//            drawAxis(for: edge, with: encoder)
//            drawAxis(for: edge.pair, with: encoder)
//        }
//
//        if isSelected
//        {
//            renderer.apply(technique: .brush, to: encoder)
//
//            let tr = Transform(scale: .init(repeating: 1.001))
//            tr.updateModelMatrix()
//
//            var modelConstants = ModelConstants()
//            modelConstants.color = .one
//            modelConstants.modelMatrix = tr.matrix
//            encoder.setVertexBytes(&modelConstants, length: MemoryLayout<ModelConstants>.size, index: 2)
//
//            var vertices2: [Vertex] = []
//
//            for face in faces
//            {
//                for edge in face.edges
//                {
//                    let color = edge === selectedEdge ? float4(1, 0, 0, 1) : float4(0, 0, 0, 1)
//
//                    vertices2.append(
//                        Vertex(pos: edge.vert.position, nor: .zero, clr: color)
//                    )
//
//                    vertices2.append(
//                        Vertex(pos: edge.next.vert.position, nor: .zero, clr: color)
//                    )
//                }
//            }
//
//            var pointer = vertexBuffer2.contents().bindMemory(to: Vertex.self, capacity: 1024)
//
//            for vertex in vertices2
//            {
//                pointer.pointee = vertex
//                pointer = pointer.advanced(by: 1)
//            }
//
//            encoder.setVertexBuffer(vertexBuffer2, offset: 0, index: 0)
//            encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: vertices2.count)
//        }
    }
    
    private func drawAxis(for edge: HalfEdge, with encoder: MTLRenderCommandEncoder)
    {
        let pos = edge.center + edge.face.plane.normal * 8
        let scale = float3(1, 1, 1) + abs(edge.face.plane.normal) * 15
        let tr1 = Transform(position: pos, scale: scale)
        tr1.updateModelMatrix()

        var modelConstants1 = ModelConstants()
        modelConstants1.color = float4(abs(edge.face.plane.normal), 1)
        modelConstants1.modelMatrix = tr1.matrix
        encoder.setVertexBytes(&modelConstants1, length: MemoryLayout<ModelConstants>.size, index: 2)

        point.render(with: encoder)
    }
}

private extension EditableMesh
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
            face.normal = normal
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
        edge0.prev = edge3
        
        edge1.vert = face.verts[1]
        edge1.face = face
        edge1.next = edge2
        edge1.prev = edge0
        
        edge2.vert = face.verts[2]
        edge2.face = face
        edge2.next = edge3
        edge2.prev = edge1
        
        edge3.vert = face.verts[3]
        edge3.face = face
        edge3.next = edge0
        edge3.prev = edge2
        
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

private func intersect(ray: Ray, lineStart: float3, lineEnd: float3) -> Float
{
    let r1 = ray.origin
    let r2 = ray.origin + ray.direction * 1024
    
    let u1 = r2 - r1
    let u2 = lineEnd - lineStart
    let u3 = cross(u1, u2)
    let s = r1 - lineEnd
    
    if length(u3) == 0 {
        return .greatestFiniteMagnitude
    }
    
    return abs( dot(s, u3) / length(u3) )
}

private func intersect(ray: Ray, face: Face) -> Bool
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
