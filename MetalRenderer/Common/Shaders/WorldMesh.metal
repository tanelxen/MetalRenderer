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
    float3 position [[attribute(0)]];
    float2 textureCoord [[attribute(1)]];
    float2 lightmapCoord [[attribute(2)]];
    float3 color [[attribute(3)]];
};

struct VertexOut
{
    float4 position [[ position ]];
    half4 color;
    float2 textureCoord;
    float2 lightmapCoord;
    float depth;
};

vertex VertexOut world_mesh_vs
(
    const VertexIn           vIn             [[ stage_in ]],
    constant SceneConstants  &viewConstants  [[ buffer(1) ]]
)
{
    float4x4 mvp = viewConstants.projectionMatrix * viewConstants.viewMatrix;
    
    VertexOut data;
    
    data.position = mvp * float4(vIn.position, 1);
    data.color = half4(vIn.color.r, vIn.color.g, vIn.color.b, 1);
    data.textureCoord = vIn.textureCoord;
    data.lightmapCoord = vIn.lightmapCoord;
    
    data.depth = data.position.z / 5000.0f;
//    data.depth = max(data.depth, 1.0f);
//    data.depth = min(data.depth, 0.0f);
//    data.depth = 1.0f - data.depth;
    
    return data;
}

constexpr sampler sampler2d(min_filter::linear, mag_filter::linear, address::repeat);

half4 adjustExposure(half4 color, float value) {
    return (1.0 + value) * color;
}

fragment half4 world_mesh_lightmapped_fs
(
    VertexOut         vOut        [[ stage_in ]],
    texture2d<half>   albedoMap   [[ texture(0) ]],
    texture2d<half>   lightMap    [[ texture(1) ]],
    constant bool     &useLightmap [[ buffer(0) ]]
)
{
    half4 albedo = albedoMap.sample(sampler2d, vOut.textureCoord);
    albedo[3] = 1.0;
    
    half4 lighting = vOut.color;
    
    if (useLightmap)
    {
        lighting = lightMap.sample(sampler2d, vOut.lightmapCoord);
    }
    
    float fog = vOut.depth * vOut.depth * vOut.depth * 0.5;

    return adjustExposure(albedo * lighting + fog, 2);
}

fragment half4 world_mesh_vertexlit_fs
(
    VertexOut         vOut        [[ stage_in ]],
    texture2d<half>   albedoMap   [[ texture(0) ]]
)
{
    half4 albedo = albedoMap.sample(sampler2d, vOut.textureCoord);
    
    return albedo * vOut.color;
}
