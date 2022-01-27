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
    float time;
};

// Vertex Shader
vertex VertexOut final_vertex_shader(const device       VertexIn *vIn   [[ buffer(0) ]],
                                     unsigned int       vertexId        [[ vertex_id ]],
                                     constant float     &time           [[ buffer(1) ]]
                                     )
{
    VertexOut out;
    
    VertexIn curVertex = vIn[vertexId];
    
    out.position = float4(curVertex.position, 1);
    out.texCoord = curVertex.texCoord;
    out.time = time;
    
    return out;
}

sampler sampler2d;

// Fragment Shader
fragment half4 final_fragment_shader(
                                     VertexOut          data        [[ stage_in ]],
                                     constant float4x4  &invCamPj   [[ buffer(1) ]],
                                     constant float4x4  &view       [[ buffer(2) ]],
                                     texture2d<float>   albedoMap   [[ texture(0) ]],
                                     texture2d<float>   normalMap   [[ texture(1) ]],
                                     texture2d<float>   positionMap [[ texture(2) ]],
                                     depth2d<float>     depthMap    [[ texture(3) ]]
                                     )
{
    
    
    float3 lightPosition = float3(10, 10, 10); // float3(sin(data.time) * 10, 10, cos(data.time) * 10);
    float3 lightColor = float3(0.9, 0.85, 0.7);
    
    float3 albedo = albedoMap.sample(sampler2d, data.texCoord).rgb;
    float3 normal = normalMap.sample(sampler2d, data.texCoord).rgb;
    float3 position = positionMap.sample(sampler2d, data.texCoord).rgb;
    
    float3 diffuse = 1.0;

    float3 lightDir = normalize(lightPosition - position);
    diffuse = max(dot(normal, lightDir), 0.0) * lightColor + 0.1;

    float dist_sqr = length_squared(lightPosition - position);
    float radius = 100;
    float attenuation = 1.0 / (1.0 + dist_sqr/radius);

    diffuse *= attenuation;
    
//    float3 viewPosition = normalize(view * float4(position, 1.0)).xyz;
//    float3 viewNormal = normalize(view * float4(normal, 0.0)).xyz;

//    float ssao = glSSAO(positionMap, data.texCoord, normal);
    float ssao = pureDepthSSAO(depthMap, data.texCoord, normal, invCamPj);
    
    float3 result = albedo * ssao * diffuse;

    return half4(result.r, result.g, result.b, 1.0);
}

