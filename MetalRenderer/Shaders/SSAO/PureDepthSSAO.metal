//
//  PureDepthSSAO.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 22.01.2022.
//

#ifndef PURE_DEPTH_SSAO
#define PURE_DEPTH_SSAO

#include <metal_stdlib>
#include "Loki.h"
using namespace metal;

float3 normalFromDepth(float curDepth, float2 texCoord, depth2d<float> depthMap);

float pureDepthSSAO(float2 texCoord, depth2d<float> depthMap)
{
    const float total_strength = 1.0;
    const float area = 0.0075;
    const float falloff = 0.000001;
    const float radius = 0.003;
    const int samples = 16;
    
    sampler sampler2d(address::repeat);
    
    Loki loki(666);
    float3 random = normalize(float3(loki.rand() * 2.0 - 1.0,
                                     loki.rand() * 2.0 - 1.0,
                                     loki.rand() * 2.0 - 1.0));
    
    float depth = depthMap.sample(sampler2d, texCoord);
    
    float3 position = float3(texCoord, depth);
    float3 normal = normalFromDepth(depth, texCoord, depthMap);
    
    float radius_depth = radius/depth;
    float occlusion = 0.0;
    
    for(int i=0; i < samples; i++)
    {
        float3 sample = normalize(float3(loki.rand() * 2.0 - 1.0,
                                         loki.rand() * 2.0 - 1.0,
                                         loki.rand() * 2.0 - 1.0));
        
        float3 ray = radius_depth * reflect(sample, random);
        
        float3 hemi_ray = position + sign(dot(ray,normal)) * ray;

        float occ_depth = depthMap.sample(sampler2d, saturate(hemi_ray.xy));
        float difference = depth - occ_depth;

        occlusion += step(falloff, difference) * (1.0-smoothstep(falloff, area, difference));
    }
    
    return 1.0 - total_strength * occlusion * (1.0 / samples);
}

float3 normalFromDepth(float curDepth, float2 texCoord, depth2d<float> depthMap)
{
    const float2 offset1 = float2(0.0,0.001);
    const float2 offset2 = float2(0.001,0.0);

    sampler sampler2d;

    float depth1 = depthMap.sample(sampler2d, texCoord + offset1);
    float depth2 = depthMap.sample(sampler2d, texCoord + offset2);

    float3 p1 = float3(offset1, depth1 - curDepth);
    float3 p2 = float3(offset2, depth2 - curDepth);

    float3 normal = cross(p1, p2);
    normal.z = -normal.z;

    return normalize(normal);
}

#endif
