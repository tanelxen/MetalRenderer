//
//  Lighting.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 30.01.2022.
//

#include <metal_stdlib>
#include "Common.metal"
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
    float3 lightPos;
};

vertex VertexOut lighting_vertex_shader(const Vertex              vIn               [[ stage_in ]],
                                        constant SceneConstants   &viewConstants    [[ buffer(1) ]],
                                        constant ModelConstants   &modelConstants   [[ buffer(2) ]])
{
    float4 worldPosition = modelConstants.modelMatrix * float4(vIn.position, 1);
    
    VertexOut out;
    
    out.position = viewConstants.projectionMatrix * viewConstants.viewMatrix * worldPosition;

    return out;
}

float shadowCalculation(float4 lightSpaceFragPos, depth2d<float> shadowMap);

constexpr sampler sampler2d;

fragment float4 lighting_fragment_shader(VertexOut          data                [[ stage_in ]],
                                        constant LightData  &light              [[ buffer(0) ]],
                                        constant float4x4   &view               [[ buffer(2) ]],
                                        constant float4x4   &lightSpaceMatrix   [[ buffer(3) ]],
                                        texture2d<float>    normalMap           [[ texture(1) ]],
                                        texture2d<float>    positionMap         [[ texture(2) ]],
                                        depth2d<float>      shadowMap           [[ texture(3) ]],
                                        depth2d<float>      depthMap            [[ texture(4) ]])
{
    float2 screenSize(normalMap.get_width(), normalMap.get_height());
    float2 texCoord = data.position.xy / screenSize;
    
    float3 normal = normalMap.sample(sampler2d, texCoord).xyz;
    float4 position = positionMap.sample(sampler2d, texCoord);
    
    float3 viewPosition = (view * position).xyz;
    
    normal.z = sqrt(1.0f - normal.x * normal.x - normal.y * normal.y);
    
    float4 lightSpaceFragPos = lightSpaceMatrix * position;
    
    float shadowCalc = shadowCalculation(lightSpaceFragPos, shadowMap);

    float3 lightColor = light.color;
    float3 lightPosition = (view * float4(light.position, 1.0)).xyz;
    float3 lightToUnit = lightPosition - viewPosition;

    float3 lightDir = normalize(lightToUnit);

    float dist_sqr = length_squared(lightToUnit);
    float radius_sqr = light.brightness * light.brightness;
    float attenuation = 1.0 - clamp(dist_sqr/radius_sqr, 0.0, 1.0);

    float3 diffuse = max(dot(normal, lightDir), 0.0) * lightColor * attenuation * (1.0 - shadowCalc);
    
    

    return float4(diffuse, 1.0);
}

float shadowCalculation(float4 lightSpaceFragPos, depth2d<float> shadowMap)
{
    float3 projCoords = lightSpaceFragPos.xyz / lightSpaceFragPos.w;
    
    float2 shadowUV = projCoords.xy * float2(0.5, -0.5) + 0.5;
//
    constexpr sampler s(coord::normalized,
                        filter::linear,
                        address::clamp_to_border,
                        border_color:: opaque_white,
                        compare_func:: greater);
//
    float bias = 0.0002;
    
    float currentDepth = projCoords.z;
    float shadow = 0.0;
    
    shadow = currentDepth - bias > shadowMap.sample(s, shadowUV) ? 1.0 : 0.0;
    
//    float2 texelSize = 1.0 / float2(shadowMap.get_width(), shadowMap.get_height());
//
//    int radius = 1;
//
//    for(int x = -radius; x <= radius; ++x)
//    {
//        for(int y = -radius; y <= radius; ++y)
//        {
//            float pcfDepth = shadowMap.sample(s, shadowUV + float2(x, y) * texelSize);
//            shadow += currentDepth - bias > pcfDepth ? 1.0 : 0.0;
//        }
//    }
//
//    shadow /= (radius * 2 * 2);

    return shadow;
}
