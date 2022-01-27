//
//  RenderPipelineStateLibrary.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

enum RenderPipelineStateTypes
{
//    case basic
//    case skysphere
//    case ssao
    case final
}

enum RenderPipelineStateLibrary
{
    private static var states: [RenderPipelineStateTypes: RenderPipelineState] = [:]
    
    static func initialize()
    {
//        states.updateValue(BasicRenderPipelineState(), forKey: .basic)
//        states.updateValue(SkysphereRenderPipelineState(), forKey: .skysphere)
//        states.updateValue(SSAORenderPipelineState(), forKey: .ssao)
//        states.updateValue(FinalRenderPipelineState(), forKey: .final)
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

//struct BasicRenderPipelineState: RenderPipelineState
//{
//    var name: String = "Basic Render Pipeline State"
//    var state: MTLRenderPipelineState
//
//    init()
//    {
//        let descriptor = MTLRenderPipelineDescriptor()
//        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
//        descriptor.colorAttachments[1].pixelFormat = Preferences.colorPixelFormat
//        descriptor.depthAttachmentPixelFormat = .depth32Float_stencil8
//        descriptor.stencilAttachmentPixelFormat = .depth32Float_stencil8
//
//        descriptor.vertexFunction = ShaderLibrary.vertex(.basic)
//        descriptor.fragmentFunction = ShaderLibrary.fragment(.basic)
//        descriptor.vertexDescriptor = VertexDescriptorLibrary.descriptor(.basic)
//
//        descriptor.label = "Basic Render"
//
//        state = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
//    }
//}

//struct SkysphereRenderPipelineState: RenderPipelineState
//{
//    var name: String = "Skysphere Render Pipeline State"
//    var state: MTLRenderPipelineState
//
//    init()
//    {
//        let descriptor = MTLRenderPipelineDescriptor()
//        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
////        descriptor.colorAttachments[1].pixelFormat = Preferences.colorPixelFormat
//        descriptor.depthAttachmentPixelFormat = .depth32Float_stencil8
//        descriptor.stencilAttachmentPixelFormat = .depth32Float_stencil8
//
//        descriptor.vertexFunction = ShaderLibrary.vertex(.skysphere)
//        descriptor.fragmentFunction = ShaderLibrary.fragment(.skysphere)
//        descriptor.vertexDescriptor = VertexDescriptorLibrary.descriptor(.basic)
//
//        descriptor.label = "Skysphere Render"
//
//        state = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
//    }
//}

//struct SSAORenderPipelineState: RenderPipelineState
//{
//    var name: String = "SSAO Render"
//    var state: MTLRenderPipelineState
//
//    init()
//    {
//        let descriptor = MTLRenderPipelineDescriptor()
//        descriptor.colorAttachments[0].pixelFormat = .r8Unorm
////        descriptor.colorAttachments[1].pixelFormat = Preferences.colorPixelFormat
////        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat
//
//        descriptor.vertexFunction = ShaderLibrary.vertex(.ssao)
//        descriptor.fragmentFunction = ShaderLibrary.fragment(.ssao)
//
//        descriptor.label = name
//
//        state = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
//    }
//}

//struct FinalRenderPipelineState: RenderPipelineState
//{
//    var name: String = "Final Render"
//    var state: MTLRenderPipelineState
//
//    init()
//    {
//        let descriptor = MTLRenderPipelineDescriptor()
//        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
////        descriptor.colorAttachments[1].pixelFormat = Preferences.colorPixelFormat
//        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat
//        descriptor.stencilAttachmentPixelFormat = .invalid
//
//        descriptor.vertexFunction = ShaderLibrary.vertex(.final)
//        descriptor.fragmentFunction = ShaderLibrary.fragment(.final)
//
//        descriptor.label = name
//
//        state = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
//    }
//}
