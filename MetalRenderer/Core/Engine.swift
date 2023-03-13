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
    static private(set) var defaultLibrary: MTLLibrary!
    
    static func ignite(device: MTLDevice)
    {
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        self.defaultLibrary = device.makeDefaultLibrary()
    }
}

enum Preferences
{
    static let colorPixelFormat: MTLPixelFormat = .bgra8Unorm_srgb
    static let depthStencilPixelFormat: MTLPixelFormat = .depth32Float
}
