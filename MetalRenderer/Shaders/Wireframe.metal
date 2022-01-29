//
//  Wireframe.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 29.01.2022.
//

#include <metal_stdlib>
#include "Common.metal"
using namespace metal;


vertex float4 wireframe_vertex_shader(constant float3           *vertices       [[ buffer(0) ]],
                                      constant SceneConstants   &viewConstants  [[ buffer(1) ]],
                                      constant ModelConstants   &modelConstants [[ buffer(2) ]],
                                      uint                      vertexID        [[ vertex_id ]])
{
    float4 position = float4(vertices[vertexID], 1);

    return viewConstants.projectionMatrix * viewConstants.viewMatrix * modelConstants.modelMatrix * position;
}

fragment half4 wireframe_fragment_shader()
{
    return half4(1.0, 0.0, 0.0, 1.0);
}
