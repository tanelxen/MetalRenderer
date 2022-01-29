//
//  ShaderLibrary.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 12.01.2022.
//

import MetalKit

enum ShaderTypes
{
    case gbuffer
    case compose
    case skysphere
    case wireframe
}

enum ShaderLibrary
{
    static private(set) var defaultLibrary: MTLLibrary!
    
    private static var shaders: [ShaderTypes : Shader] = [:]
    
    static func initialize()
    {
        defaultLibrary = Engine.device.makeDefaultLibrary()
        
        shaders.updateValue(GBufferShader(), forKey: .gbuffer)
        shaders.updateValue(SkysphereShader(), forKey: .skysphere)
        shaders.updateValue(ComposeShader(), forKey: .compose)
        shaders.updateValue(WireframeShader(), forKey: .wireframe)
    }
    
    static func vertex(_ type: ShaderTypes) -> MTLFunction
    {
        shaders[type]!.vertex
    }
    
    static func fragment(_ type: ShaderTypes) -> MTLFunction
    {
        shaders[type]!.fragment!
    }
}

private protocol Shader
{
    var vertex: MTLFunction { get }
    var fragment: MTLFunction? { get }
}

private struct GBufferShader: Shader
{
    var vertex: MTLFunction
    var fragment: MTLFunction?
    
    init()
    {
        vertex = ShaderLibrary.defaultLibrary.makeFunction(name: "gbuffer_vertex_shader")!
        vertex.label = "GBuffer Vertex Shader"
        
        fragment = ShaderLibrary.defaultLibrary.makeFunction(name: "gbuffer_fragment_shader")!
        fragment?.label = "GBuffer Fragment Shader"
    }
}

private struct SkysphereShader: Shader
{
    var vertex: MTLFunction
    var fragment: MTLFunction?
    
    init()
    {
        vertex = ShaderLibrary.defaultLibrary.makeFunction(name: "skysphere_vertex_shader")!
        vertex.label = "Skysphere Vertex Shader"
        
        fragment = ShaderLibrary.defaultLibrary.makeFunction(name: "skysphere_fragment_shader")!
        fragment?.label = "Skysphere Fragment Shader"
    }
}

private struct ComposeShader: Shader
{
    var vertex: MTLFunction
    var fragment: MTLFunction?
    
    init()
    {
        vertex = ShaderLibrary.defaultLibrary.makeFunction(name: "compose_vertex_shader")!
        vertex.label = "Compose Vertex Shader"
        
        fragment = ShaderLibrary.defaultLibrary.makeFunction(name: "compose_fragment_shader")!
        fragment?.label = "Compose Fragment Shader"
    }
}

private struct WireframeShader: Shader
{
    var vertex: MTLFunction
    var fragment: MTLFunction?
    
    init()
    {
        vertex = ShaderLibrary.defaultLibrary.makeFunction(name: "wireframe_vertex_shader")!
        vertex.label = "Wireframe Vertex Shader"
        
        fragment = ShaderLibrary.defaultLibrary.makeFunction(name: "wireframe_fragment_shader")!
        fragment?.label = "Wireframe Fragment Shader"
    }
}

private struct InstancingShader: Shader
{
    var vertex: MTLFunction
    var fragment: MTLFunction?
    
    init()
    {
        vertex = ShaderLibrary.defaultLibrary.makeFunction(name: "instanced_vertex_shader")!
        vertex.label = "Instanced Vertex Shader"
        
        fragment = ShaderLibrary.defaultLibrary.makeFunction(name: "basic_fragment_shader")!
        fragment?.label = "Basic Fragment Shader"
    }
}
