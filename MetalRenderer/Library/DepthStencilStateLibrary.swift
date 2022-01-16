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
    var name: String = "Basic Render Pipeline State"
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
