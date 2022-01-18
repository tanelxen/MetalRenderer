//
//  Types.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 12.01.2022.
//

import simd

typealias float2 = SIMD2<Float>
typealias float3 = SIMD3<Float>
typealias float4 = SIMD4<Float>

struct Vertex: sizeable
{
    let position: float3
    let uv: float2
    
    let normal: float3
    let tangent: float3
}

struct ModelConstants: sizeable
{
    var modelMatrix = matrix_identity_float4x4
}

struct SceneConstants: sizeable
{
    var viewMatrix = matrix_identity_float4x4
    var projectionMatrix = matrix_identity_float4x4
    var cameraPosition: float3 = .zero
}

struct MaterialConstants: sizeable
{
    var isLit = false
    var useBaseColorMap = false
    var useNormalMap = false
    
    var color: float4 = float4(1.0, 1.0, 1.0, 1.0)
    var ambient: float3 = float3(0.01, 0.01, 0.01)
    var diffuse: float3 = float3(1.0, 1.0, 1.0)
    var specular: float3 = float3(1.0, 1.0, 1.0)
    var shininess: Float = 3
}

struct LightData: sizeable
{
    var position: float3 = .zero
    var color: float3 = float3(1.0, 1.0, 1.0)
    var brightness: Float = 0.9
    
    var ambientIntensity: Float = 0.5
    var diffuseIntensity: Float = 0.9
}
