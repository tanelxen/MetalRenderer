//
//  PureDepthSSAO.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 22.01.2022.
//

#ifndef PURE_DEPTH_SSAO
#define PURE_DEPTH_SSAO

#include <metal_stdlib>
#include "../Loki/Loki.h"
using namespace metal;

// https://github.com/jhk2/dxsandbox/blob/master/kdx/kdx/samples/ao/ssao.hlsl

sampler sampler_default;

//constant float3 taps[16] = {
//    float3(-0.364452, -0.014985, -0.513535),
//    float3(0.004669, -0.445692, -0.165899),
//    float3(0.607166, -0.571184, 0.377880),
//    float3(-0.607685, -0.352123, -0.663045),
//    float3(-0.235328, -0.142338, 0.925718),
//    float3(-0.023743, -0.297281, -0.392438),
//    float3(0.918790, 0.056215, 0.092624),
//    float3(0.608966, -0.385235, -0.108280),
//    float3(-0.802881, 0.225105, 0.361339),
//    float3(-0.070376, 0.303049, -0.905118),
//    float3(-0.503922, -0.475265, 0.177892),
//    float3(0.035096, -0.367809, -0.475295),
//    float3(-0.316874, -0.374981, -0.345988),
//    float3(-0.567278, -0.297800, -0.271889),
//    float3(-0.123325, 0.197851, 0.626759),
//    float3(0.852626, -0.061007, -0.144475)
//};

#define RADIUS 0.02
#define NUM_TAPS 16
#define SCALE 1.0

float pureDepthSSAO(depth2d<float> depth_map, float2 texCoord, float3 viewNorm, constant float4x4 &inv_projection)
{
    // reconstruct the view space position from the depth map
    float start_Z = depth_map.sample(sampler_default, texCoord);
    float start_Y = 1.0 - texCoord.y; // texture coordinates for Metal have origin in top left, but in camera space origin is in bottom left
    float3 start_Pos = float3(texCoord.x, start_Y, start_Z);
    float3 ndc_Pos = (2.0 * start_Pos) - 1.0;
    float4 unproject = inv_projection * float4(ndc_Pos, 1.0);
    float3 viewPos = unproject.xyz / unproject.w;
    
    Loki loki(666);
    float3 random = normalize(float3(loki.rand() * 2.0 - 1.0,
                                     loki.rand() * 2.0 - 1.0,
                                     loki.rand() * 2.0 - 1.0));
    

    float total = 0.0;
    
    for (uint i = 0; i < NUM_TAPS; i++)
    {
        float3 sample = normalize(float3(loki.rand() * 2.0 - 1.0,
                                         loki.rand() * 2.0 - 1.0,
                                         loki.rand() * 2.0 - 1.0));

//        float3 sample = taps[i];

        sample *= loki.rand();

        float3 offset = RADIUS * reflect(sample, random);

        float2 offTex = texCoord + float2(offset.x, -offset.y);

        const float off_start_Z = depth_map.sample(sampler_default, offTex);

        const float3 off_start_Pos = float3(offTex.x, start_Y + offset.y, off_start_Z);
        const float3 off_ndc_Pos = (2.0 * off_start_Pos) - 1.0;
        const float4 off_unproject = inv_projection * float4(off_ndc_Pos, 1.0);
        const float3 off_viewPos = off_unproject.xyz / off_unproject.w;
        const float3 diff = off_viewPos - viewPos;

        float occlusion = max(0.0, dot(viewNorm, normalize(diff)));

        float attenuation = SCALE / (1.0 + length(diff) / RADIUS);
        attenuation = smoothstep(0, 1, attenuation);

        occlusion *= attenuation; // attenuate the effect linearly with distance

        total += (1.0 - occlusion);
    }

    total /= NUM_TAPS;
    
    return total;
}

float positionBasedSSAO(texture2d<float> positionMap, float2 texCoord, float3 viewNorm)
{
    float3 viewPos = positionMap.sample(sampler_default, texCoord).xyz;
    
    Loki loki(666);
    float3 random = normalize(float3(loki.rand() * 2.0 - 1.0,
                                     loki.rand() * 2.0 - 1.0,
                                     loki.rand() * 2.0 - 1.0));
    
    float total = 0.0;
    
    for (uint i = 0; i < NUM_TAPS; i++)
    {
        float3 sample = normalize(float3(loki.rand() * 2.0 - 1.0,
                                         loki.rand() * 2.0 - 1.0,
                                         loki.rand() * 2.0 - 1.0));

        sample *= loki.rand();

        float3 offset = RADIUS * reflect(sample, random);
        float2 offTex = texCoord + float2(offset.x, -offset.y);
        float3 offPos = positionMap.sample(sampler_default, offTex.xy).xyz; // view space position of offset point

        float3 diff = offPos - viewPos;

        float occlusion = max(0.0, dot(viewNorm, normalize(diff)));

        float attenuation = SCALE / (1.0 + length(diff) / RADIUS);
        attenuation = smoothstep(0, 1, attenuation);

        occlusion *= attenuation; // attenuate the effect linearly with distance

        total += (1.0 - occlusion);
    }

    total /= NUM_TAPS;
    
    return total;
}

float3 ViewPosFromDepth(float depth, float2 texCoord, constant float4x4 &projMatrixInv)
{
    float z = depth * 2.0 - 1.0;

    float4 clipSpacePosition = float4(texCoord * 2.0 - 1.0, z, 1.0);
    float4 viewSpacePosition = projMatrixInv * clipSpacePosition;
    
    return viewSpacePosition.xyz;
}

float3 WorldPosFromDepth(float depth, float2 texCoord, constant float4x4 &projMatrixInv, constant float4x4 &viewMatrixInv)
{
    float z = depth * 2.0 - 1.0;

    float4 clipSpacePosition = float4(texCoord * 2.0 - 1.0, z, 1.0);
    float4 viewSpacePosition = projMatrixInv * clipSpacePosition;

    // Perspective division
    viewSpacePosition /= viewSpacePosition.w;

    float4 worldSpacePosition = viewMatrixInv * viewSpacePosition;

    return worldSpacePosition.xyz;
}

#endif
