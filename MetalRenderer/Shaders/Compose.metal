//
//  Final.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 19.01.2022.
//

#include <metal_stdlib>
#include "SSAO/ssao.h"
using namespace metal;

struct VertexIn
{
    packed_float3 position;
    packed_float2 texCoord;
};

struct VertexOut
{
    float4 position [[ position ]];
    float2 texCoord;
};

struct LightData
{
    float3 position;
    float3 color;
    float brightness;
    
    float ambientIntensity;
    float diffuseIntensity;
};

// Vertex Shader
vertex VertexOut compose_vertex_shader(const device VertexIn *vIn [[ buffer(0) ]], unsigned int vertexId [[ vertex_id ]])
{
    VertexOut out;
    
    VertexIn curVertex = vIn[vertexId];
    
    out.position = float4(curVertex.position, 1);
    out.texCoord = curVertex.texCoord;
    
    return out;
}

float3 lensflare(float2 uv, float2 pos);

sampler sampler2d;

// Fragment Shader
fragment half4 compose_fragment_shader(VertexOut          data        [[ stage_in ]],
                                       constant float4x4  &invCamPj   [[ buffer(1) ]],
                                       texture2d<float>   albedoMap   [[ texture(0) ]],
                                       texture2d<float>   normalMap   [[ texture(1) ]],
                                       depth2d<float>     depthMap    [[ texture(2) ]],
                                       texture2d<float>   lightMap    [[ texture(3) ]])
{
    float3 albedo = albedoMap.sample(sampler2d, data.texCoord).rgb;
    
    float2 normalXY = normalMap.sample(sampler2d, data.texCoord).xy;
    float normalZ = sqrt(1.0f - normalXY.x * normalXY.x - normalXY.y * normalXY.y);
    float3 normal = float3(normalXY, normalZ);
    
    float3 diffuse = lightMap.sample(sampler2d, data.texCoord).rgb;
    
    diffuse = saturate(diffuse + 0.02);
    
    float ssao = pureDepthSSAO(depthMap, data.texCoord, normal, invCamPj);
    
    float3 result = albedo * ssao * diffuse;

    return half4(result.r, result.g, result.b, 1.0);
}
