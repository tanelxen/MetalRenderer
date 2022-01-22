//
//  Final.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 19.01.2022.
//

#include <metal_stdlib>
#include "SSAO/PureDepthSSAO.h"
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

// Fragment Shader
fragment half4 final_fragment_shader(
                                     VertexOut          data        [[ stage_in ]],
                                     constant float4x4  &projection [[ buffer(1) ]],
                                     texture2d<float>   albedoMap   [[ texture(0) ]],
                                     texture2d<float>   normalMap   [[ texture(1) ]],
                                     texture2d<float>   positionMap [[ texture(2) ]],
                                     depth2d<float>     depthMap    [[ texture(3) ]]
                                     )
{
    sampler sampler2d;
    
    float3 lightPosition = float3(sin(data.time) * 10, 10, cos(data.time) * 10);
    float3 lightColor = float3(0.9, 0.85, 0.7);
    
    float3 albedo = albedoMap.sample(sampler2d, data.texCoord).rgb;
    float3 normal = normalMap.sample(sampler2d, data.texCoord).rgb;
    float3 position = positionMap.sample(sampler2d, data.texCoord).rgb;
        

    float3 lightDir = normalize(lightPosition - position);
    float3 diffuse = max(dot(normal, lightDir), 0.0) * lightColor + 0.1;

//    float3 viewDir  = normalize(-position);
//    float3 halfwayDir = normalize(lightDir + viewDir);
//    float spec = pow(max(dot(normal, halfwayDir), 0.0), 10.0) * 0.05;
//    float3 specular = lightColor * spec;

    float dist_sqr = length_squared(lightPosition - position);
    float radius = 100;
    float attenuation = 1.0 / (1.0 + dist_sqr/radius); // 1.0 / (1.0 + 0.05 * dist + 0.01 * dist * dist);
    
    diffuse  *= attenuation;
//    specular *= attenuation;
    
    float ssao = pureDepthSSAO(data.texCoord, depthMap);
    
    float3 result = albedo * saturate(ssao + 0.2) * diffuse;

    return half4(result.r, result.g, result.b, 1.0);
}

