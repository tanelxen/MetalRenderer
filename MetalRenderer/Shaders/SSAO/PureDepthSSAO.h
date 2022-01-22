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

float pureDepthSSAO(float2 texCoord, depth2d<float> depthMap);

#endif /* PureDepthSSAO_h */
