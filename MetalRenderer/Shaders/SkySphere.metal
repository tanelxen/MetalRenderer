//
//  SkySphere.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 19.01.2022.
//

#include <metal_stdlib>
#include "Common.metal"
using namespace metal;

// Vertex Shader
vertex RasterizerData skysphere_vertex_shader(const Vertex              vIn             [[ stage_in ]],
                                              constant SceneConstants   &viewConstants  [[ buffer(1) ]],
                                              constant ModelConstants   &modelConstants [[ buffer(2) ]])
{
    float4 worldPosition = modelConstants.modelMatrix * float4(vIn.position, 1);
    
    RasterizerData data;
    
    float4x4 skyViewMatrix = viewConstants.viewMatrix;
    skyViewMatrix[3][0] = 0;
    skyViewMatrix[3][1] = 0;
    skyViewMatrix[3][2] = 0;
     
    data.position = viewConstants.projectionMatrix * skyViewMatrix * worldPosition;
    data.uv = vIn.uv;
    
    return data;
}

// Fragment Shader
fragment half4 skysphere_fragment_shader(RasterizerData     data            [[ stage_in ]],
                                         sampler            sampler2d       [[ sampler(0) ]],
                                         texture2d<float>   baseColorMap    [[ texture(0) ]])
{
    float4 color = baseColorMap.sample(sampler2d, data.uv, level(0));
    
    return half4(color.r, color.g, color.b, color.a);
}

