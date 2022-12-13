//
//  WorldMesh.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.02.2022.
//

#include <metal_stdlib>
#include "Common.metal"
using namespace metal;

/**
 Отрисовка статичной геометрии мира (BSP)
 */

struct VertexIn
{
    float4 position [[attribute(0)]];
    float4 normal [[attribute(1)]];
    float4 color [[attribute(2)]];
    float2 textureCoord [[attribute(3)]];
    float2 lightmapCoord [[attribute(4)]];
};

struct VertexOut
{
    float4 position [[ position ]];
    float2 textureCoord;
    float2 lightmapCoord;
};

vertex VertexOut world_mesh_vs
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
    
    data.position = mvp * vIn.position;
    data.textureCoord = vIn.textureCoord;
    data.lightmapCoord = vIn.lightmapCoord;
    
    return data;
}

constexpr sampler sampler2d(min_filter::linear, mag_filter::linear, address::repeat);

fragment half4 world_mesh_fs
(
    VertexOut         vOut        [[ stage_in ]],
    texture2d<half>   albedoMap   [[ texture(0) ]],
    texture2d<half>   lightMap    [[ texture(1) ]]
)
{
    
    half4 albedo = albedoMap.sample(sampler2d, vOut.textureCoord);
    half4 lighting = lightMap.sample(sampler2d, vOut.lightmapCoord);
    
    return albedo * lighting;
}
