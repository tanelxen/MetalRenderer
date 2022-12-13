//
//  SkeletalMesh.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 15.02.2022.
//

#include <metal_stdlib>
#include "Common.metal"
using namespace metal;

/**
 Отрисовка анимированных моделей
 */

struct VertexIn
{
    float3 position [[attribute(0)]];
    float2 textureCoord [[attribute(1)]];
};

struct VertexOut
{
    float4 position [[ position ]];
    float2 textureCoord;
};

vertex VertexOut skeletal_mesh_vs
(
    const VertexIn           vIn             [[ stage_in ]],
    constant SceneConstants  &viewConstants  [[ buffer(1) ]],
    constant ModelConstants  &modelConstants [[ buffer(2) ]]
)
{
//    float4x4 quakeToMetal = float4x4(
//        1, 0, 0, 0,
//        0, 0, 1, 0,
//        0, -1, 0, 0,
//        0, 0, 0, 1
//    );
    
    float4x4 mvp = viewConstants.projectionMatrix * viewConstants.viewMatrix * modelConstants.modelMatrix;
    
    VertexOut data;
    
    data.position = mvp * float4(vIn.position, 1.0);
    data.textureCoord = vIn.textureCoord;
    
    return data;
}

constexpr sampler sampler2d(min_filter::linear, mag_filter::linear, address::repeat);

fragment half4 skeletal_mesh_fs
(
    VertexOut         vOut        [[ stage_in ]],
    texture2d<half>   albedoMap   [[ texture(0) ]]
)
{
    
    half4 albedo = albedoMap.sample(sampler2d, vOut.textureCoord);
    
    return albedo;
}



