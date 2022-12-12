//
//  StaticMesh.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 14.02.2022.
//

import simd
//import Assimp
import MetalKit

class StaticMesh
{
    private var vertexBuffer: MTLBuffer!
    
    private var indexBuffer: MTLBuffer!
    private var indexCount: Int = 0
    
    private var texture: MTLTexture!
    
    init?(name: String, ext: String)
    {
//        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return nil }
//        
//        guard let scene = try? AiScene(file: url.path, flags: [.removeRedundantMaterials]) else { return nil }
//        
//        guard let aiMesh = scene.meshes.first else { return nil }
//        
//        let aiVertices = aiMesh.vertices.chunked(into: 3)
//        let aiTexCoords = aiMesh.texCoords.0?.compactMap({ $0 }).chunked(into: 3)
//        
//        var vertices: [StaticMeshVertex] = []
//        
//        for (aiVertex, texCoords) in zip(aiVertices, aiTexCoords!)
//        {
//            let position = float3(aiVertex[0], aiVertex[1], aiVertex[2])
//            let uv = float2(texCoords[0], texCoords[1])
//            let vertex = StaticMeshVertex(position: position, texCoord: uv)
//            
//            vertices.append(vertex)
//        }
//        
//        var indices: [UInt32] = []
//        
//        for aiFace in aiMesh.faces
//        {
//            indices.append(contentsOf: aiFace.indices)
//        }
//        
//        let assetURL = Bundle.main.url(forResource: "shotgun", withExtension: "jpg")!
//        let devTexture = TextureManager.shared.getTexture(url: assetURL, origin: .bottomLeft)!
//        
//        vertexBuffer = Engine.device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<StaticMeshVertex>.stride, options: [])
//        indexBuffer = Engine.device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt32>.stride, options: [])
//        
//        indexCount = indices.count
//        
//        texture = devTexture
    }
    
    func renderWithEncoder(_ encoder: MTLRenderCommandEncoder)
    {
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(texture, index: 0)
        
        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: indexCount,
                                      indexType: .uint32,
                                      indexBuffer: indexBuffer,
                                      indexBufferOffset: 0)
    }
    
    static func vertexDescriptor() -> MTLVertexDescriptor
    {
        let descriptor = MTLVertexDescriptor()
        var offset: Int = 0
        
        // Position
        descriptor.attributes[0].format = .float3
        descriptor.attributes[0].bufferIndex = 0
        descriptor.attributes[0].offset = offset
        offset += float3.size
        
        // UV
        descriptor.attributes[1].format = .float2
        descriptor.attributes[1].bufferIndex = 0
        descriptor.attributes[1].offset = offset
        offset += float2.size
        
        descriptor.layouts[0].stride = StaticMeshVertex.stride
        
        return descriptor
    }
}

private struct StaticMeshVertex: sizeable
{
    let position: float3
    let texCoord: float2
}

extension Array
{
    func chunked(into size: Int) -> [[Element]]
    {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
