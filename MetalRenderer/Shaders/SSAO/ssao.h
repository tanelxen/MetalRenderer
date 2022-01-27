//
//  PureDepthSSAO.h
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 22.01.2022.
//

#ifndef PureDepthSSAO_h
#define PureDepthSSAO_h

#include <metal_stdlib>
using namespace metal;

float pureDepthSSAO(depth2d<float> depth_map, float2 texCoord, float3 viewNorm, constant float4x4 &invCamPj);
float positionBasedSSAO(texture2d<float> positionMap, float2 texCoord, float3 viewNorm);
float crytekSSAO(texture2d<float> normalMap, texture2d<float> positionMap, float2 texCoord, constant float4x4  &projection);

#endif /* PureDepthSSAO_h */
