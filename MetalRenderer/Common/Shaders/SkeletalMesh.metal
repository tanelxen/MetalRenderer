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
    uint boneIndex [[attribute(2)]];
};

struct VertexOut
{
    float4 position [[ position ]];
    float2 textureCoord;
    half4 ambient;
};

vertex VertexOut skeletal_mesh_vs
(
    const VertexIn           vIn             [[ stage_in ]],
    constant SceneConstants  &viewConstants  [[ buffer(1) ]],
    constant ModelConstants  &modelConstants [[ buffer(2) ]],
    constant float4x4        *boneTransforms [[ buffer(3) ]]
)
{
    float4x4 mvp = viewConstants.projectionMatrix * viewConstants.viewMatrix * modelConstants.modelMatrix;
    
    VertexOut data;
    
    float4x4 boneTransform = boneTransforms[vIn.boneIndex];
    
    data.position = mvp * boneTransform * float4(vIn.position, 1.0);
    data.textureCoord = vIn.textureCoord;
    data.ambient = half4(modelConstants.color);
    
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
    return albedo * vOut.ambient;
}



