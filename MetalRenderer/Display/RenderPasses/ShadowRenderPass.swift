//
//  ShadowRenderPass.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.02.2022.
//

import MetalKit

class ShadowRenderPass
{
    private (set) var shadowTexture: MTLTexture!
    
    private (set) var passDescriptor: MTLRenderPassDescriptor!
    
    private (set) var bspPipelineState: MTLRenderPipelineState!
    private (set) var staticPipelineState: MTLRenderPipelineState!
    private (set) var skeletalPipelineState: MTLRenderPipelineState!
    
    private var width: Int = 1
    private var height: Int = 1
    
    init()
    {
        createBspPipelineState()
    }
    
    func setup(for size: CGSize)
    {
        self.width = Int(size.width)
        self.height = Int(size.height)
        
        setuphadowMap()
        
        passDescriptor = MTLRenderPassDescriptor()
        passDescriptor.depthAttachment.texture = shadowTexture
        passDescriptor.depthAttachment.loadAction = .clear
        passDescriptor.depthAttachment.storeAction = .store
        passDescriptor.depthAttachment.clearDepth = 1.0
        passDescriptor.renderTargetArrayLength = 6
    }
    
    func doPass(with commandBuffer: MTLCommandBuffer?, _ closure: ()->Void)
    {
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: passDescriptor)
        
        renderEncoder?.label = "Shadow Render Command Encoder"

        renderEncoder?.pushDebugGroup("Shadow Render")
        
        renderEncoder?.setDepthStencilState(DepthStencilStateLibrary[.shadow])
        
        renderEncoder?.setCullMode(.front)
        
        renderEncoder?.setRenderPipelineState(bspPipelineState)
        
        closure()
        
        renderEncoder?.popDebugGroup()
        
        renderEncoder?.endEncoding()
    }
    
    private func setuphadowMap()
    {
        let size: Int = 512
        
        let shadowTextureDescriptor = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .depth16Unorm,
                                                                                 size: size,
                                                                                 mipmapped: false)
        
        shadowTextureDescriptor.usage = [.renderTarget, .shaderRead]
        shadowTextureDescriptor.storageMode = .private
        
        shadowTexture = Engine.device.makeTexture(descriptor: shadowTextureDescriptor)!
        shadowTexture.label = "Shadow"
    }
    
    private func createBspPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.depthAttachmentPixelFormat = .depth16Unorm

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "shadowmap_vertex_shader")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "shadowmap_fragment_shader")
        descriptor.vertexDescriptor = VertexDescriptorLibrary.descriptor(.basic)
        descriptor.inputPrimitiveTopology = .triangle

        descriptor.label = "Shadow Render Pipeline State"

        bspPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
}

