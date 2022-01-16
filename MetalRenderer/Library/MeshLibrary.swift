//
//  MeshLibrary.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

//import MetalKit
//
//class QuadMesh: Mesh
//{
//    var vertices: [Vertex] = []
//    var vertexBuffer: MTLBuffer!
//    var vertexCount: Int {
//        vertices.count
//    }
//    
//    init()
//    {
//        createVertices()
//        createBuffers()
//    }
//    
//    func drawPrimitives(with encoder: MTLRenderCommandEncoder?)
//    {
//        encoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//        encoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
//    }
//    
//    private func createVertices()
//    {
//        vertices = [
//            Vertex(position: float3(-1, 1, 0), normal: float3(0, 1, 0), uv: float2(0, 0)),   //Top Left
//            Vertex(position: float3(-1,-1, 0), normal: float3(0, 1, 0), uv: float2(0, 1)),   //Bottom Left
//            Vertex(position: float3( 1, 1, 0), normal: float3(0, 1, 0), uv: float2(1, 0)),   //Top Right
//            
//            Vertex(position: float3(-1,-1, 0), normal: float3(0, 1, 0), uv: float2(0, 1)),   //Bottom Left
//            Vertex(position: float3( 1,-1, 0), normal: float3(0, 1, 0), uv: float2(1, 1)),   //Bottom Right
//            Vertex(position: float3( 1, 1, 0), normal: float3(0, 1, 0), uv: float2(1, 0)),   //Top Right
//        ]
//    }
//    
//    private func createBuffers()
//    {
//        vertexBuffer = Engine.device.makeBuffer(bytes: vertices, length: Vertex.stride(vertices.count), options: [])
//    }
//}
