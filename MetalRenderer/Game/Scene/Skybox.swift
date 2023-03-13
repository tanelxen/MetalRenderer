//
//  Skybox.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 04.02.2022.
//

import MetalKit

class Skybox
{
    private let mesh: MTKMesh
    private let texture: MTLTexture!
    
    init()
    {
        let allocator = MTKMeshBufferAllocator(device: Engine.device)
        
        let cube = MDLMesh(boxWithExtent: [1,1,1], segments: [1, 1, 1],
                           inwardNormals: true, geometryType: .triangles,
                           allocator: allocator)
        
        mesh = try! MTKMesh(mesh: cube, device: Engine.device)
        
        texture = TextureManager.shared.loadCubeTexture(imageName: "night-sky")
    }
    
    func renderWithEncoder(_ encoder: MTLRenderCommandEncoder)
    {
        encoder.setFragmentTexture(texture, index: 1)
        encoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)
        
        let submesh = mesh.submeshes[0]

        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: submesh.indexCount,
                                      indexType: submesh.indexType,
                                      indexBuffer: submesh.indexBuffer.buffer,
                                      indexBufferOffset: 0)
    }
    
    static func vertexDescriptor() -> MTLVertexDescriptor
    {
        let descriptor = MTLVertexDescriptor()
        var offset: Int = 0
        
        // Position
        descriptor.attributes[0].format = .float4
        descriptor.attributes[0].bufferIndex = 0
        descriptor.attributes[0].offset = offset
        offset += float4.size
        
        // Normal
        descriptor.attributes[1].format = .float4
        descriptor.attributes[1].bufferIndex = 0
        descriptor.attributes[1].offset = offset
        offset += float4.size
        
        // Color
        descriptor.attributes[2].format = .float4
        descriptor.attributes[2].bufferIndex = 0
        descriptor.attributes[2].offset = offset
        offset += float4.size
        
        // UV0
        descriptor.attributes[3].format = .float2
        descriptor.attributes[3].bufferIndex = 0
        descriptor.attributes[3].offset = offset
        offset += float2.size
        
        // UV1
        descriptor.attributes[4].format = .float2
        descriptor.attributes[4].bufferIndex = 0
        descriptor.attributes[4].offset = offset
        offset += float2.size
        
        descriptor.layouts[0].stride = offset
        
        return descriptor
    }
}
