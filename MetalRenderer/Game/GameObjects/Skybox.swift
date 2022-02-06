//
//  Skybox.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 04.02.2022.
//

import MetalKit

class Skybox
{
    let mesh: MTKMesh
    let vertexDescriptor: MTLVertexDescriptor?
    
    init()
    {
        let allocator = MTKMeshBufferAllocator(device: Engine.device)
        
        let cube = MDLMesh(boxWithExtent: [1,1,1], segments: [1, 1, 1],
                           inwardNormals: true, geometryType: .triangles,
                           allocator: allocator)
        
        vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(cube.vertexDescriptor)
        
        do {
          mesh = try MTKMesh(mesh: cube, device: Engine.device)
        }
        catch {
          fatalError("failed to create skybox mesh")
        }
    }
    
    func render(with renderEncoder: MTLRenderCommandEncoder)
    {
        renderEncoder.pushDebugGroup("Skybox")
//        renderEncoder.setRenderPipelineState(pipelineState)
//        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)
        
//      var viewMatrix = uniforms.viewMatrix
//      viewMatrix.columns.3 = [0, 0, 0, 1]
//      var viewProjectionMatrix = uniforms.projectionMatrix * viewMatrix
//
//      renderEncoder.setVertexBytes(&viewProjectionMatrix, length: MemoryLayout<float4x4>.stride, index: 1)
        
//        renderEncoder.setFragmentTexture(texture, index: Int(BufferIndexSkybox.rawValue))

        let submesh = mesh.submeshes[0]

        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: submesh.indexCount,
                                            indexType: submesh.indexType,
                                            indexBuffer: submesh.indexBuffer.buffer,
                                            indexBufferOffset: 0)
    }
}
