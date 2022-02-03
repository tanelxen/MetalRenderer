//
//  SkySphere.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 19.01.2022.
//

#include <metal_stdlib>
#include "Common.metal"
using namespace metal;

struct VertexOut
{
    float4 position [[ position ]];
    float3 textureCoordinates;
    float2 uv;
};

// Vertex Shader
vertex VertexOut skysphere_vertex_shader(const Vertex              vIn             [[ stage_in ]],
                                              constant SceneConstants   &viewConstants  [[ buffer(1) ]],
                                              constant ModelConstants   &modelConstants [[ buffer(2) ]])
{
//    float4 worldPosition = modelConstants.modelMatrix * float4(vIn.position, 1);
    
//    RasterizerData data;
    
    float4x4 skyViewMatrix = viewConstants.viewMatrix;
    skyViewMatrix[3][0] = 0;
    skyViewMatrix[3][1] = 0;
    skyViewMatrix[3][2] = 0;
    skyViewMatrix[3][3] = 1;
     
//    data.position = viewConstants.projectionMatrix * skyViewMatrix * worldPosition;
    
//
//    return data;
    
    
    VertexOut out;
    out.position = (viewConstants.projectionMatrix * skyViewMatrix * float4(vIn.position, 1)).xyww;
    out.textureCoordinates = vIn.position;
    out.uv = vIn.uv;
    
    out.textureCoordinates.y = -out.textureCoordinates.y;
    
    return out;
}

// Fragment Shader
fragment half4 skysphere_fragment_shader(VertexOut          data            [[ stage_in ]],
                                         texture2d<float>   baseColorMap    [[ texture(0) ]],
                                         texturecube<half>  cubeTexture     [[ texture(1) ]])
{
    constexpr sampler default_sampler(min_filter::linear, mag_filter::linear);
    
//    return cubeTexture.sample(default_sampler, data.textureCoordinates);
    
    float4 color = baseColorMap.sample(default_sampler, data.uv, level(0));
    
    return half4(color.r, color.g, color.b, color.a);
}

