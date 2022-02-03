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

float3 fog(float distance, float3 color);

sampler sampler2d;

// Fragment Shader
fragment float4 compose_fragment_shader(VertexOut            data        [[ stage_in ]],
                                       constant LightData   &light      [[ buffer(0) ]],
                                       constant float4x4    &invCamPj   [[ buffer(1) ]],
                                       texture2d<float>     albedoMap   [[ texture(0) ]],
                                       texture2d<float>     normalMap   [[ texture(1) ]],
                                       depth2d<float>       depthMap    [[ texture(2) ]],
                                       texture2d<float>     lightMap    [[ texture(3) ]],
                                       depthcube<float>     shadowMap   [[ texture(4) ]],
                                       texture2d<float>     positionMap [[ texture(5) ]])
{
    float3 albedo = albedoMap.sample(sampler2d, data.texCoord).rgb;

    float2 normalXY = normalMap.sample(sampler2d, data.texCoord).xy;
    float normalZ = sqrt(1.0f - normalXY.x * normalXY.x - normalXY.y * normalXY.y);
    float3 normal = float3(normalXY, normalZ);

    float3 diffuse = lightMap.sample(sampler2d, data.texCoord).rgb + 0.002;

//    diffuse = saturate(diffuse + 0.02);

    float ssao = pureDepthSSAO(depthMap, data.texCoord, normal, invCamPj);

    float3 result = saturate(albedo * diffuse) * ssao;
    
    const float exposure = 5.0;
    const float gamma = 2.2;
    
    // тональная компрессия с экспозицией
    float3 mapped = float3(1.0) - exp(-result * exposure);
    
    // гамма-коррекция
    mapped = pow(mapped, float3(1.0 / gamma));

    return float4(mapped, 1.0);
}
