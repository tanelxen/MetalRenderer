//
//  Particles.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 14.09.2023.
//

#include <metal_stdlib>
#include "Common.metal"
using namespace metal;

struct VertexIn
{
    float3 position [[ attribute(0) ]];
    float4 color [[attribute(1) ]];
    float size [[attribute(2) ]];
};

struct VertexOut
{
    float4 position [[ position ]];
    float pointSize [[ point_size ]];
    half4 color;
};

vertex VertexOut particle_vs
(
    constant VertexIn       *vertices       [[ buffer(0) ]],
    constant SceneConstants &viewConstants  [[ buffer(1) ]],
    uint                    vertexId        [[ vertex_id ]]
)
{
    VertexOut data;
    
    VertexIn vtx = vertices[vertexId];
    
    float4 mvPosition = viewConstants.viewMatrix * float4(vtx.position, 1);
    float4 position = viewConstants.projectionMatrix * mvPosition;
    
    float2 viewportSize = viewConstants.viewportSize;
    
//    float pointSize = viewportSize.y * viewConstants.projectionMatrix[1][1] * radius / position.w;
//    float pointSize = viewportSize.x * radius / length(mvPosition.xyz);
    float pointSize = viewportSize.y * vtx.size / position.w;
    
    data.position = position;
    data.pointSize = pointSize;
    data.color = half4(vtx.color);
    
    return data;
}

constexpr sampler sampler2d(min_filter::linear, mag_filter::linear, address::repeat);

fragment half4 particle_fs
(
    VertexOut       vOut        [[ stage_in ]],
    float2          texcoord    [[ point_coord ]],
    texture2d<half> texture     [[ texture(0) ]]
)
{
    return vOut.color * texture.sample(sampler2d, texcoord);
}
