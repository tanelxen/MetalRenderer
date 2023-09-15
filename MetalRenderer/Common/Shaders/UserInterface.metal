//
//  UserInterface.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 15.09.2023.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn
{
    float2 position [[ attribute(0) ]];
    float2 textureCoord [[ attribute(1) ]];
};

struct VertexOut
{
    float4 position [[ position ]];
    float2 textureCoord;
    half4 color;
};

vertex VertexOut user_interface_vs
(
    constant VertexIn   *vertices           [[ buffer(0) ]],
    constant float4x4   &projectionMatrix   [[ buffer(1) ]],
    constant float4     &color              [[ buffer(2) ]],
    uint                vertexId            [[ vertex_id ]]
)
{
    VertexOut data;
    
    VertexIn current = vertices[vertexId];
    
    data.position = projectionMatrix * float4(current.position, 0, 1);
    data.textureCoord = current.textureCoord;
    data.color = half4(color);
    
    return data;
}

constexpr sampler sampler2d(min_filter::linear, mag_filter::linear, address::repeat);

fragment half4 user_interface_fs
(
    VertexOut       vOut        [[ stage_in ]],
    texture2d<half> texture     [[ texture(0) ]]
)
{
    half4 color = vOut.color;
    
    if (!is_null_texture(texture))
    {
        color = color * texture.sample(sampler2d, vOut.textureCoord);
    }
    
    return color;
}
