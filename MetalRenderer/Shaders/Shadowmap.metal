//
//  Shadowmap.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 01.02.2022.
//

#include <metal_stdlib>
#include "Common.metal"
using namespace metal;

vertex float4 shadowmap_vertex_shader(const Vertex              vIn                 [[ stage_in ]],
                                      constant float4x4         &lightSpaceMatrix   [[ buffer(1) ]],
                                      constant ModelConstants   &modelConstants     [[ buffer(2) ]])
{
    return lightSpaceMatrix * modelConstants.modelMatrix * float4(vIn.position, 1);
}
