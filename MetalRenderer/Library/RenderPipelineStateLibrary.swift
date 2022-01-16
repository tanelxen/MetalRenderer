//
//  RenderPipelineStateLibrary.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

enum RenderPipelineStateTypes
{
    case basic
}

enum RenderPipelineStateLibrary
{
    private static var states: [RenderPipelineStateTypes: RenderPipelineState] = [:]
    
    static func initialize()
    {
        states.updateValue(BasicRenderPipelineState(), forKey: .basic)
    }
    
    static subscript(_ type: RenderPipelineStateTypes) -> MTLRenderPipelineState
    {
        states[type]!.state
    }
}

protocol RenderPipelineState
{
    var name: String { get }
    var state: MTLRenderPipelineState { get }
}

struct BasicRenderPipelineState: RenderPipelineState
{
    var name: String = "Basic Render Pipeline State"
    var state: MTLRenderPipelineState
    
    init()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        descriptor.depthAttachmentPixelFormat = .depth32Float
        
        descriptor.vertexFunction = ShaderLibrary.vertex(.basic)
        descriptor.fragmentFunction = ShaderLibrary.fragment(.basic)
        descriptor.vertexDescriptor = VertexDescriptorLibrary.descriptor(.basic)
        
        descriptor.label = name
        
        state = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
}
