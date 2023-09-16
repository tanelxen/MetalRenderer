//
//  Common.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

#include <metal_stdlib>
using namespace metal;

struct SceneConstants
{
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float2 viewportSize;
};

struct ModelConstants
{
    float4x4 modelMatrix;
    float4 color;
};
