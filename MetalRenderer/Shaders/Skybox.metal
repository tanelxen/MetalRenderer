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
    float3 texCoords;
};

vertex VertexOut skybox_vertex_shader
(
    constant float3           *vertices       [[ buffer(0) ]],
    constant SceneConstants   &viewConstants  [[ buffer(1) ]],
    constant ModelConstants   &modelConstants [[ buffer(2) ]],
    uint                      vertexID        [[ vertex_id ]]
)
{
    float4 position = float4(vertices[vertexID], 1);
    
    float4x4 skyViewMatrix = viewConstants.viewMatrix;
    
    // Делаем бесконечный масштаб
    skyViewMatrix[3][0] = 0;
    skyViewMatrix[3][1] = 0;
    skyViewMatrix[3][2] = 0;
    skyViewMatrix[3][3] = 1;
     
    VertexOut out;
    out.position = (viewConstants.projectionMatrix * skyViewMatrix * position).xyww;
    out.texCoords = position.xyz;
    
    // переворачиваем под видовую матрицу в системе quake
    out.texCoords = out.texCoords.xzy;
    out.texCoords.z = -out.texCoords.z;
    
    return out;
}

fragment half4 skybox_fragment_shader
(
    VertexOut          data            [[ stage_in ]],
    texturecube<float> cubeTexture     [[ texture(0) ]]
)
{
    constexpr sampler default_sampler;
    
    float4 color = cubeTexture.sample(default_sampler, data.texCoords);
    
    return half4(color);
}

