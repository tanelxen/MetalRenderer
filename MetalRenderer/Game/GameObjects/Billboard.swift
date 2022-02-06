//
//  Billboard.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 06.02.2022.
//

import MetalKit

class Billboard
{
    let mesh: MTKMesh
    let vertexDescriptor: MTLVertexDescriptor?
    
    private var _pipelineState: MTLRenderPipelineState?
    
    init()
    {
        let allocator = MTKMeshBufferAllocator(device: Engine.device)
        
        let plane = MDLMesh(planeWithExtent: [1,1,1],
                            segments: [1, 1, 1],
                            geometryType: .quads,
                            allocator: allocator)
        
        vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(plane.vertexDescriptor)
        
        do {
          mesh = try MTKMesh(mesh: plane, device: Engine.device)
        }
        catch {
          fatalError("failed to create billboard mesh")
        }
        
        createBillboardPipelineState()
    }
    
    func render(with renderEncoder: MTLRenderCommandEncoder)
    {
        renderEncoder.pushDebugGroup("Billboard")

        renderEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)

        let submesh = mesh.submeshes[0]

        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: submesh.indexCount,
                                            indexType: submesh.indexType,
                                            indexBuffer: submesh.indexBuffer.buffer,
                                            indexBufferOffset: 0)
    }
}

extension Billboard
{
    private func createBillboardPipelineState()
    {
        let defaultLibrary = Engine.device.makeDefaultLibrary()
        
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = defaultLibrary?.makeFunction(name: "billboard_vertex_shader")
        descriptor.fragmentFunction = defaultLibrary?.makeFunction(name: "billboard_fragment_shader")
        descriptor.vertexDescriptor = vertexDescriptor

        descriptor.label = "Billboard Pipeline State"

        _pipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
}

