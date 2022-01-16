//
//  SamplerStateLibrary.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

enum SamplerStateTypes
{
    case none
    case linear
}

enum SamplerStateLibrary
{
    private static var states: [SamplerStateTypes: SamplerState] = [:]
    
    static func initialize()
    {
        states.updateValue(LinearSamplerState(), forKey: .linear)
    }
    
    static subscript(_ type: SamplerStateTypes) -> MTLSamplerState
    {
        return (states[type]?.samplerState!)!
    }
}

private protocol SamplerState
{
    var name: String { get }
    var samplerState: MTLSamplerState! { get }
}

private class LinearSamplerState: SamplerState
{
    var name: String = "Linear Sampler State"
    var samplerState: MTLSamplerState!
    
    init()
    {
        let descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .linear
        descriptor.magFilter = .linear
        descriptor.label = name
        
        samplerState = Engine.device.makeSamplerState(descriptor: descriptor)
    }
}
