//
//  PipelineState.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 01.02.2022.
//

import MetalKit

class PipelineState
{
    init()
    {
        _defaultLibrary = Engine.device.makeDefaultLibrary()
    }
    
    private let _defaultLibrary: MTLLibrary?
    
    lazy var geometry: MTLRenderPipelineState = {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
        descriptor.colorAttachments[1].pixelFormat = .rg16Float
        descriptor.colorAttachments[2].pixelFormat = .rgba16Float
        
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat
        descriptor.stencilAttachmentPixelFormat = Preferences.depthStencilPixelFormat
        
        

        descriptor.vertexFunction = _defaultLibrary?.makeFunction(name: "gbuffer_vertex_shader")
        descriptor.fragmentFunction = _defaultLibrary?.makeFunction(name: "gbuffer_fragment_shader")
        descriptor.vertexDescriptor = VertexDescriptorLibrary.descriptor(.basic)

        descriptor.label = "GBuffer Render Pipeline State"

        return try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }()
}
