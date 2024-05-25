//
//  MeshUtilityRenderer.swift
//  Sandbox
//
//  Created by Fedor Artemenkov on 24.05.2024.
//

/*
 Thing for drawing control points, edges etc of selected mesh
 */

import MetalKit
import simd

final class MeshUtilityRenderer
{
    var mesh: EditableMesh?
    var selectionMode: SelectionMode = .face
    
    private var dotsVertexBuffer: MTLBuffer!
    private var linesVertexBuffer: MTLBuffer!
    
    private let box = MTKGeometry(.box)
    
    init()
    {
        let length = MemoryLayout<Vertex>.stride * MAX_VERTS
        dotsVertexBuffer = Engine.device.makeBuffer(length: length)
        linesVertexBuffer = Engine.device.makeBuffer(length: length)
    }
    
    func render(with renderer: ForwardRenderer)
    {
        drawEdges(with: renderer)
        drawSelectedEdge(with: renderer)
        drawControlPoints(with: renderer)
    }
    
    private func drawEdges(with renderer: ForwardRenderer)
    {
        guard let mesh = self.mesh else { return }
        
        var renderItem = RenderItem(technique: .dot)
        
        renderItem.cullMode = .none
        renderItem.isSupportLineMode = true
        renderItem.primitiveType = .line
        
        var vertices: [Vertex] = []
        
        for face in mesh.faces
        {
            let vertClr = float4(1, 1, 1, 1)
            
            vertices.append(contentsOf: [
                Vertex(pos: face.verts[0].position, clr: vertClr),
                Vertex(pos: face.verts[1].position, clr: vertClr),
                Vertex(pos: face.verts[1].position, clr: vertClr),
                Vertex(pos: face.verts[2].position, clr: vertClr),
                Vertex(pos: face.verts[2].position, clr: vertClr),
                Vertex(pos: face.verts[3].position, clr: vertClr),
                Vertex(pos: face.verts[3].position, clr: vertClr),
                Vertex(pos: face.verts[0].position, clr: vertClr)
            ])
        }
        
        var pointer = linesVertexBuffer.contents().bindMemory(to: Vertex.self, capacity: MAX_VERTS)
        
        for vertex in vertices
        {
            pointer.pointee = vertex
            pointer = pointer.advanced(by: 1)
        }
    
        renderItem.vertexBuffer = linesVertexBuffer
        renderItem.numVertices = vertices.count
        
        renderer.add(item: renderItem)
    }
    
    private func drawControlPoints(with renderer: ForwardRenderer)
    {
        guard let mesh = self.mesh else { return }
        
        var renderItem = RenderItem(technique: .dot)
        
        renderItem.cullMode = .none
        renderItem.isSupportLineMode = true
        renderItem.primitiveType = .point
        
        var vertices: [Vertex] = []
        
        for face in mesh.faces
        {
            if selectionMode == .face
            {
                let faceClr = face.isHighlighted ? float4(0, 1, 0, 1) : float4(1, 0, 1, 1)
                
                vertices.append(
                    Vertex(pos: face.center, clr: faceClr)
                )
            }
            else if selectionMode == .edge
            {
                for edge in face.edges
                {
                    let edgeClr = edge.isHighlighted ? float4(0, 1, 0, 1) : float4(1, 0, 0, 1)
                    
                    vertices.append(
                        Vertex(pos: edge.center, clr: edgeClr)
                    )
                }
            }
//            else if selectionMode == .vertex
//            {
//                let vertClr = float4(1, 1, 1, 1)
//
//                for vert in face.verts
//                {
//                    vertices.append(
//                        Vertex(pos: vert.position, clr: vertClr)
//                    )
//                }
//            }
        }
        
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
    
    private func drawSelectedEdge(with renderer: ForwardRenderer)
    {
        guard let edge = self.mesh?.selectedEdge else { return }
        
        let p1 = edge.vert.position
        let p2 = edge.next.vert.position

        // Вычисление вектора направления
        let direction = normalize(p2 - p1)

        // Определение ортонормального базиса
        let newY = direction
        var arbitrary = SIMD3<Float>(1, 0, 0)
        if abs(dot(arbitrary, newY)) > 0.99 {
            arbitrary = SIMD3<Float>(0, 1, 0)
        }
        let newZ = normalize(cross(newY, arbitrary))
        let newX = normalize(cross(newY, newZ))

        // Формирование матрицы поворота
        let rotationMatrix = float4x4(
            SIMD4<Float>(newX.x, newY.x, newZ.x, 0),
            SIMD4<Float>(newX.y, newY.y, newZ.y, 0),
            SIMD4<Float>(newX.z, newY.z, newZ.z, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
        
        var renderItem = RenderItem(mtkMesh: box)
        
        renderItem.isSupportLineMode = false
        renderItem.allowedViews = [.perspective]
        renderItem.tintColor = [0, 1, 0, 1]
        
        renderItem.transform = Transform(position: edge.center)
        renderItem.transform.scale = [0.5, length(p2 - p1), 0.5]
        renderItem.transform.parent = rotationMatrix
        
        renderer.add(item: renderItem)
    }
}

private struct Vertex
{
    var pos: float3 = .zero
    var clr: float4 = .one
}

private let MAX_VERTS: Int = 1024
