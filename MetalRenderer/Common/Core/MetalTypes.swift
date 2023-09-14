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

//struct Vertex: sizeable
//{
//    let position: float3
//    let uv: float2
//    
//    let normal: float3
//    let tangent: float3
//}

struct ModelConstants: sizeable
{
    var modelMatrix = matrix_identity_float4x4
    var color = float3(1, 1, 1)
}

struct SkeletalConstants: sizeable
{
    var boneTransforms: [matrix_float4x4]
}

struct SceneConstants: sizeable
{
    var viewMatrix = matrix_identity_float4x4
    var projectionMatrix = matrix_identity_float4x4
    var viewportSize = float2(x: 1, y: 1)
}
