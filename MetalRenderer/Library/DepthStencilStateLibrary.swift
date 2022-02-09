//
//  DepthStencilStateLibrary.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

enum DepthStencilStateTypes
{
    case less
    case shadow
    case gbuffer
    case lighting
    case compose
    case sky
}

enum DepthStencilStateLibrary
{
    private static var depthStencilStates: [DepthStencilStateTypes: DepthStencilState] = [:]
    
    public static func intitialize()
    {
        createDefaultDepthStencilStates()
    }
    
    private static func createDefaultDepthStencilStates()
    {
        depthStencilStates.updateValue(LessDepthStencilState(), forKey: .less)
        depthStencilStates.updateValue(ShadowDepthStencilState(), forKey: .shadow)
        depthStencilStates.updateValue(GBufferDepthStencilState(), forKey: .gbuffer)
        depthStencilStates.updateValue(LightingDepthStencilState(), forKey: .lighting)
        depthStencilStates.updateValue(ComposeDepthStencilState(), forKey: .compose)
        depthStencilStates.updateValue(SkyDepthStencilState(), forKey: .sky)
    }
    
    static subscript(_ depthStencilStateType: DepthStencilStateTypes) -> MTLDepthStencilState
    {
        return depthStencilStates[depthStencilStateType]!.depthStencilState
    }
}

protocol DepthStencilState
{
    var name: String { get }
    var depthStencilState: MTLDepthStencilState! { get }
}

class LessDepthStencilState: DepthStencilState
{
    var name: String = "Less Depth Stencil State"
    var depthStencilState: MTLDepthStencilState!
    
    init()
    {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.isDepthWriteEnabled = true
        descriptor.depthCompareFunction = .less
        descriptor.label = name
        
        depthStencilState = Engine.device.makeDepthStencilState(descriptor: descriptor)
    }
}

class ShadowDepthStencilState: DepthStencilState
{
    var name: String = "Shadow Depth Stencil State"
    var depthStencilState: MTLDepthStencilState!
    
    init()
    {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.isDepthWriteEnabled = true
        descriptor.depthCompareFunction = .less
        descriptor.label = name
        
        depthStencilState = Engine.device.makeDepthStencilState(descriptor: descriptor)
    }
}

class GBufferDepthStencilState: DepthStencilState
{
    var name: String = "GBuffer Depth Stencil State"
    var depthStencilState: MTLDepthStencilState!
    
    init()
    {
//        let stencilStateDescriptor: MTLStencilDescriptor = MTLStencilDescriptor()
//        stencilStateDescriptor.depthStencilPassOperation = .replace
        
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.isDepthWriteEnabled = true
        descriptor.depthCompareFunction = .less
//        descriptor.frontFaceStencil = stencilStateDescriptor
//        descriptor.backFaceStencil = stencilStateDescriptor
        descriptor.label = name
        
        depthStencilState = Engine.device.makeDepthStencilState(descriptor: descriptor)
    }
}

class LightingDepthStencilState: DepthStencilState
{
    var name: String = "Lighting Depth Stencil State"
    var depthStencilState: MTLDepthStencilState!
    
    init()
    {
//        let stencilStateDescriptor: MTLStencilDescriptor = MTLStencilDescriptor()
//        stencilStateDescriptor.stencilCompareFunction = .notEqual
        
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.isDepthWriteEnabled = false
        descriptor.depthCompareFunction = .less
//        descriptor.frontFaceStencil = stencilStateDescriptor
//        descriptor.backFaceStencil = stencilStateDescriptor
        descriptor.label = name
        
        depthStencilState = Engine.device.makeDepthStencilState(descriptor: descriptor)
    }
}

class ComposeDepthStencilState: DepthStencilState
{
    var name: String = "Compose Depth Stencil State"
    var depthStencilState: MTLDepthStencilState!
    
    init()
    {
//        let stencilStateDescriptor: MTLStencilDescriptor = MTLStencilDescriptor()
//        stencilStateDescriptor.stencilCompareFunction = .equal
//        stencilStateDescriptor.readMask = 0xFF
//        stencilStateDescriptor.writeMask = 0x0
        
        let descriptor = MTLDepthStencilDescriptor()
//        descriptor.frontFaceStencil = stencilStateDescriptor
//        descriptor.backFaceStencil = stencilStateDescriptor
        descriptor.isDepthWriteEnabled = false
        descriptor.depthCompareFunction = .always
        descriptor.label = name
        
        depthStencilState = Engine.device.makeDepthStencilState(descriptor: descriptor)
    }
}

class SkyDepthStencilState: DepthStencilState
{
    var name: String = "GBuffer Depth Stencil State"
    var depthStencilState: MTLDepthStencilState!
    
    init()
    {
//        let stencilStateDescriptor: MTLStencilDescriptor = MTLStencilDescriptor()
//        stencilStateDescriptor.stencilCompareFunction = .notEqual
//        stencilStateDescriptor.readMask = 0x0
        
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.isDepthWriteEnabled = false
        descriptor.depthCompareFunction = .lessEqual
//        descriptor.frontFaceStencil = stencilStateDescriptor
//        descriptor.backFaceStencil = stencilStateDescriptor
        descriptor.label = name
        
        depthStencilState = Engine.device.makeDepthStencilState(descriptor: descriptor)
    }
}
