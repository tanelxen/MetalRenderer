//
//  ShaderLibrary.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 12.01.2022.
//

import MetalKit

enum ShaderTypes
{
    case basic
}

enum ShaderLibrary
{
    static private(set) var defaultLibrary: MTLLibrary!
    
    private static var shaders: [ShaderTypes : Shader] = [:]
    
    static func initialize()
    {
        defaultLibrary = Engine.device.makeDefaultLibrary()
        
        shaders.updateValue(BasicShader(), forKey: .basic)
    }
    
    static func vertex(_ type: ShaderTypes) -> MTLFunction
    {
        shaders[type]!.vertex
    }
    
    static func fragment(_ type: ShaderTypes) -> MTLFunction
    {
        shaders[type]!.fragment
    }
}

private protocol Shader
{
    var vertex: MTLFunction { get }
    var fragment: MTLFunction { get }
}

private struct BasicShader: Shader
{
    var vertex: MTLFunction
    var fragment: MTLFunction
    
    init()
    {
        vertex = ShaderLibrary.defaultLibrary.makeFunction(name: "basic_vertex_shader")!
        vertex.label = "Basic Vertex Shader"
        
        fragment = ShaderLibrary.defaultLibrary.makeFunction(name: "basic_fragment_shader")!
        fragment.label = "Basic Fragment Shader"
    }
}
