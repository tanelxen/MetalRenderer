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

float shadowCalculation(float3 fragToLight, texturecube<float> shadowMap, float far_plane);
float shadowCalculation(float3 fragToLight, depthcube<float> shadowMap, float far_plane);

constexpr sampler sampler2d;

fragment float4 lighting_fragment_shader(VertexOut          data                [[ stage_in ]],
                                        constant LightData  &light              [[ buffer(0) ]],
                                        constant float4x4   &view               [[ buffer(2) ]],
                                        texture2d<float>    normalMap           [[ texture(1) ]],
                                        texture2d<float>    positionMap         [[ texture(2) ]],
                                        depthcube<float>    shadowMap           [[ texture(3) ]])
{
    float2 screenSize(normalMap.get_width(), normalMap.get_height());
    float2 texCoord = data.position.xy / screenSize;
    
    float3 normal = normalMap.sample(sampler2d, texCoord).xyz;
    float4 position = positionMap.sample(sampler2d, texCoord);
    
    float3 viewPosition = (view * position).xyz;
    
    normal.z = sqrt(1.0f - normal.x * normal.x - normal.y * normal.y);

    float3 lightColor = light.color;
    float3 lightPosition = (view * float4(light.position, 1.0)).xyz;
    float3 lightToUnit = lightPosition - viewPosition;

    float3 lightDir = normalize(lightToUnit);
    
    float3 lightDirWS = position.xyz - light.position;
    float shadow = shadowCalculation(lightDirWS, shadowMap, light.radius);

    float dist_sqr = length_squared(lightToUnit);
    float radius_sqr = light.radius * light.radius;
    float attenuation = 1.0 - clamp(dist_sqr/radius_sqr, 0.0, 1.0);

    float3 diffuse = max(dot(normal, lightDir), 0.0) * lightColor * light.diffuseIntensity * attenuation * (1.0 - shadow);

    return float4(diffuse, 1.0);
}

float shadowCalculation(float4 lightSpaceFragPos, depth2d<float> shadowMap)
{
    float3 projCoords = lightSpaceFragPos.xyz / lightSpaceFragPos.w;
    
    float2 shadowUV = projCoords.xy * float2(0.5, -0.5) + 0.5;

    constexpr sampler s(coord::normalized,
                        filter::linear,
                        address::clamp_to_border,
                        border_color:: opaque_white,
                        compare_func:: greater);
    
    float bias = 0.0002;
    
    float currentDepth = projCoords.z;
    float shadow = 0.0;
    
    shadow = currentDepth - bias > shadowMap.sample(s, shadowUV) ? 1.0 : 0.0;

    return shadow;
}

#define SAMPLES 20

constant float3 sampleOffsetDirections[SAMPLES] = {
    float3( 1,  1,  1), float3( 1, -1,  1), float3(-1, -1,  1), float3(-1,  1,  1),
    float3( 1,  1, -1), float3( 1, -1, -1), float3(-1, -1, -1), float3(-1,  1, -1),
    float3( 1,  1,  0), float3( 1, -1,  0), float3(-1, -1,  0), float3(-1,  1,  0),
    float3( 1,  0,  1), float3(-1,  0,  1), float3( 1,  0, -1), float3(-1,  0, -1),
    float3( 0,  1,  1), float3( 0, -1,  1), float3( 0, -1, -1), float3( 0,  1, -1),
};

float shadowCalculation(float3 fragToLight, depthcube<float> shadowMap, float far_plane)
{
    constexpr sampler s;
    
    float3 texCoords = float3(fragToLight.x, -fragToLight.y, fragToLight.z);

    float currentDepth = length(fragToLight);
    
    float shadow = 0.0;
    float bias   = 0.001;
    float diskRadius = 0.01;
    
    int numSamples = 3;
    
    for(int i = 0; i < numSamples; ++i)
    {
        float closestDepth = shadowMap.sample(s, texCoords + sampleOffsetDirections[i] * diskRadius);
        closestDepth *= far_plane;   // обратное преобразование из диапазона [0...1]
        
        shadow += currentDepth - bias > closestDepth ? 1.0 : 0.0;
    }
    
    shadow /= float(numSamples);
    
    return shadow;
}
