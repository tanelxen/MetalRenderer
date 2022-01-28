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

sampler sampler2d;

// Fragment Shader
fragment half4 compose_fragment_shader(VertexOut          data        [[ stage_in ]],
                                       constant float4x4  &invCamPj   [[ buffer(1) ]],
                                       constant float4x4  &view       [[ buffer(2) ]],
                                       constant LightData *lights     [[ buffer(3) ]],
                                       constant int       &lightCount [[ buffer(4) ]],
                                       texture2d<float>   albedoMap   [[ texture(0) ]],
                                       texture2d<float>   normalMap   [[ texture(1) ]],
                                       texture2d<float>   positionMap [[ texture(2) ]],
                                       depth2d<float>     depthMap    [[ texture(3) ]])
{
    float3 albedo = albedoMap.sample(sampler2d, data.texCoord).rgb;
    float3 normal = normalMap.sample(sampler2d, data.texCoord).rgb;
    float3 position = positionMap.sample(sampler2d, data.texCoord).rgb;
    
    float3 diffuse = 0.0;
    
    for(int i = 0; i < lightCount; i++)
    {
        LightData light = lights[i];
        
        float3 lightColor = light.color;
        float3 lightPosition = (view * float4(light.position, 1.0)).xyz;
        float3 lightToUnit = lightPosition - position;
        
        float3 lightDir = normalize(lightToUnit);
        
        float dist_sqr = length_squared(lightToUnit);
        float radius_sqr = light.brightness * light.brightness;
        float attenuation = 1.0 / (1.0 + dist_sqr/radius_sqr);
        
        diffuse += max(dot(normal, lightDir), 0.0) * lightColor * attenuation;
    }
    
    diffuse = saturate(diffuse + 0.1);
    
//    float3 viewPosition = normalize(view * float4(position, 1.0)).xyz;
//    float3 viewNormal = normalize(view * float4(normal, 0.0)).xyz;

//    float ssao = glSSAO(positionMap, data.texCoord, normal);
    float ssao = pureDepthSSAO(depthMap, data.texCoord, normal, invCamPj);
    
    float3 result = albedo * ssao * diffuse;

    return half4(result.r, result.g, result.b, 1.0);
}

