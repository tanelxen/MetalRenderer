//
//  SkySphere.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 19.01.2022.
//

#include <metal_stdlib>
#include "Common.metal"
using namespace metal;

struct VertexIn
{
    float4 position [[attribute(0)]];
    float4 normal [[attribute(1)]];
    float4 color [[attribute(2)]];
    float2 textureCoord [[attribute(3)]];
    float2 lightmapCoord [[attribute(4)]];
};

struct VertexOut
{
    float4 position [[ position ]];
    float3 texCoords;
};

vertex VertexOut skybox_vertex_shader
(
    const VertexIn          vIn             [[ stage_in ]],
    constant SceneConstants &viewConstants  [[ buffer(1) ]],
    constant ModelConstants &modelConstants [[ buffer(2) ]]
)
{

    float4x4 skyViewMatrix = viewConstants.viewMatrix;
    skyViewMatrix[3][0] = 0;
    skyViewMatrix[3][1] = 0;
    skyViewMatrix[3][2] = 0;
    skyViewMatrix[3][3] = 1;
     
    VertexOut out;
    out.position = (viewConstants.projectionMatrix * skyViewMatrix * vIn.position).xyww;
    out.texCoords = vIn.position.xyz;
    
    out.texCoords.x = -out.texCoords.x;
    
    return out;
}

fragment half4 skybox_fragment_shader
(
    VertexOut          data            [[ stage_in ]],
    texture2d<float>   baseColorMap    [[ texture(0) ]],
    texturecube<float> cubeTexture     [[ texture(1) ]]
)
{
    constexpr sampler default_sampler;
    
    float4 color = cubeTexture.sample(default_sampler, data.texCoords);
    
    return half4(color);
}

