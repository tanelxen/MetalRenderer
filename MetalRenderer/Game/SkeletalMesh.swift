//
//  SkeletalMesh.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 15.02.2022.
//

import MetalKit

class SkeletalMesh
{
    private var meshes: [SkeletalMeshData] = []
    
    init?(name: String, ext: String)
    {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        
        let mdl = HLModel(data: data)
        
        let assetURL = Bundle.main.url(forResource: "dev_256", withExtension: "jpeg")!
        let devTexture = TextureManager.shared.getTexture(url: assetURL, origin: .topLeft)!
        
        for mdlMesh in mdl.meshes
        {
            let vertices = mdlMesh.vertexBuffer.map( { SkeletalMeshVertex(position: $0.position, texCoord: $0.texCoord) } )
            let indices = mdlMesh.indexBuffer.map( { UInt32($0) } )
            
            let vertexBuffer = Engine.device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<SkeletalMeshVertex>.stride, options: [])
            let indexBuffer = Engine.device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt32>.stride, options: [])
            
            let mesh = SkeletalMeshData(texture: devTexture,
                                        vertexBuffer: vertexBuffer!,
                                        indexBuffer: indexBuffer!,
                                        indexCount: indices.count)
            
            meshes.append(mesh)
        }
    }
    
    func renderWithEncoder(_ encoder: MTLRenderCommandEncoder)
    {
        for mesh in meshes
        {
            encoder.setVertexBuffer(mesh.vertexBuffer, offset: 0, index: 0)
            encoder.setFragmentTexture(mesh.texture, index: 0)
            
            encoder.drawIndexedPrimitives(type: .triangle,
                                          indexCount: mesh.indexCount,
                                          indexType: .uint32,
                                          indexBuffer: mesh.indexBuffer,
                                          indexBufferOffset: 0)
        }
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
        
        descriptor.layouts[0].stride = SkeletalMeshVertex.stride
        
        return descriptor
    }
}

private struct SkeletalMeshData
{
    let texture: MTLTexture!
    let vertexBuffer: MTLBuffer
    let indexBuffer: MTLBuffer
    let indexCount: Int
}

private struct SkeletalMeshVertex: sizeable
{
    let position: float3
    let texCoord: float2
}
