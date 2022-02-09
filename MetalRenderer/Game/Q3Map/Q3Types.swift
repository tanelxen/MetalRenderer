//
//  Q3Types.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.02.2022.
//

import Foundation
import simd

struct Q3Vertex
{
    var position: float4 = float4(0, 0, 0, 0)
    var normal: float4 = float4(0, 0, 0, 0)
    var color: float4 = float4(0, 0, 0, 0)
    var textureCoord: float2 = float2(0, 0)
    var lightmapCoord: float2 = float2(0, 0)
    
//    var position: float3 = float3(0, 0, 0)
//    var uv: float2 = float2(0, 0)
//    var normal: float3 = float3(0, 0, 0)
//    var tangent: float3 = float3(0, 0, 0)
}

func +(left: Q3Vertex, right: Q3Vertex) -> Q3Vertex
{
    return Q3Vertex(
        position: left.position + right.position,
        normal: left.normal + right.normal,
        color: left.color + right.color,
        textureCoord: left.textureCoord + right.textureCoord,
        lightmapCoord: left.lightmapCoord + right.lightmapCoord
    )
}

func *(left: Q3Vertex, right: Float) -> Q3Vertex
{
    return Q3Vertex(
        position: left.position * right,
        normal: left.normal * right,
        color: left.color * right,
        textureCoord: left.textureCoord * right,
        lightmapCoord: left.lightmapCoord * right
    )
}

typealias Q3Lightmap = Array<(UInt8, UInt8, UInt8, UInt8)>

enum Q3FaceType: Int
{
    case polygon = 1
    case patch = 2
    case mesh = 3
    case billboard = 4
}

struct Q3Face
{
    let textureName: String
    let lightmapIndex: Int
    let vertexIndices: Array<UInt32>
}
