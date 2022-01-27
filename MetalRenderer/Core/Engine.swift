//
//  Engine.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 12.01.2022.
//

import MetalKit

enum Engine
{
    static private(set) var device: MTLDevice!
    static private(set) var commandQueue: MTLCommandQueue!
    
    static func ignite(device: MTLDevice)
    {
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        
        ShaderLibrary.initialize()
        TextureLibrary.initialize()
        
        VertexDescriptorLibrary.initialize()
        DepthStencilStateLibrary.intitialize()
        SamplerStateLibrary.initialize()
        
        RenderPipelineStateLibrary.initialize()
    }
}

enum Preferences
{
    static let colorPixelFormat: MTLPixelFormat = .bgra8Unorm_srgb
    static let depthStencilPixelFormat: MTLPixelFormat = .depth24Unorm_stencil8
}
