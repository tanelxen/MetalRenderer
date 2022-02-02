//
//  Shaders.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 11.01.2022.
//

#include "Common.metal"

#include <metal_stdlib>
using namespace metal;

vertex RasterizerData gbuffer_vertex_shader(const Vertex              vIn             [[ stage_in ]],
                                            constant SceneConstants   &viewConstants  [[ buffer(1) ]],
                                            constant ModelConstants   &modelConstants [[ buffer(2) ]])
{
    float4x4 mvp = viewConstants.projectionMatrix * viewConstants.viewMatrix * modelConstants.modelMatrix;
    
    float4 worldPosition = modelConstants.modelMatrix * float4(vIn.position, 1);
    
    RasterizerData data;
    
    data.position = mvp * float4(vIn.position, 1);
    data.uv = vIn.uv;
    
    data.worldPosition = worldPosition;
    
    data.surfaceNormal = normalize(modelConstants.modelMatrix * float4(vIn.normal, 0.0)).xyz;
    data.surfaceTangent = normalize(modelConstants.modelMatrix * float4(vIn.tangent, 0.0)).xyz;
    data.surfaceBitangent = normalize(modelConstants.modelMatrix * float4(cross(vIn.normal, vIn.tangent), 0.0)).xyz;
    
    data.viewNormal = normalize(viewConstants.viewMatrix * modelConstants.modelMatrix * float4(vIn.normal, 0.0)).xyz;
    data.viewPosition = viewConstants.viewMatrix * modelConstants.modelMatrix * float4(vIn.position, 1.0);
    
    data.eyeVector = normalize(viewConstants.cameraPosition - data.worldPosition.xyz);
    
    return data;
}

struct FragOut
{
    float4 albedo   [[ color(0) ]];
    half2 normal   [[ color(1) ]];
    float4 position [[ color(2) ]];
};

fragment FragOut gbuffer_fragment_shader(RasterizerData             data            [[ stage_in ]],
                                         constant MaterialConstants &material       [[ buffer(1) ]],
                                         texture2d<float>           baseColorMap    [[ texture(0) ]],
                                         texture2d<float>           normalMap       [[ texture(1) ]])
{
    
    constexpr sampler sampler2d(min_filter::linear, mag_filter::linear, address::repeat);
    
    float4 albedo = material.color;
    
    if (material.useBaseColorMap)
    {
        albedo = baseColorMap.sample(sampler2d, data.uv);
    }
    
    float3 unitNormal = normalize(data.surfaceNormal);
    
    if (material.useNormalMap)
    {
        float3 sampleNormal = normalMap.sample(sampler2d, data.uv).rgb * 2 - 1;

        float3x3 TBN = { data.surfaceTangent, data.surfaceBitangent, data.surfaceNormal };

        unitNormal = TBN * sampleNormal;
    }
    
    FragOut out;
    
    out.albedo = albedo;
    out.normal = half2(data.viewNormal.xy);
    out.position = data.worldPosition;
    
    return out;
}
