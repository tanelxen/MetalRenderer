//
//  Wireframe.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 29.01.2022.
//

#include <metal_stdlib>
#include "Common.metal"
using namespace metal;

struct VertexIn
{
    float3 position [[attribute(0)]];
    float2 textureCoord [[attribute(1)]];
};

struct VertexOut
{
    float4 position [[ position ]];
    float2 textureCoord;
    float3 color;
};

vertex VertexOut basic_vs(constant VertexIn       *vertices       [[ buffer(0) ]],
                          constant SceneConstants &viewConstants  [[ buffer(1) ]],
                          constant ModelConstants &modelConstants [[ buffer(2) ]],
                          uint                    vertexID        [[ vertex_id ]])
{
    float4x4 mvp = viewConstants.projectionMatrix * viewConstants.viewMatrix * modelConstants.modelMatrix;
    
    VertexOut data;
    
    data.position = mvp * float4(vertices[vertexID].position, 1);
    data.textureCoord = vertices[vertexID].textureCoord;
    data.color = modelConstants.color;
    
    return data;
}

vertex VertexOut basic_inst_vs(constant VertexIn          *vertices       [[ buffer(0) ]],
                               constant SceneConstants    &viewConstants  [[ buffer(1) ]],
                               constant ModelConstants    *modelConstants [[ buffer(2) ]],
                               uint                       vertexID        [[ vertex_id ]],
                               uint                       instanceID      [[ instance_id ]])
{
    ModelConstants instance = modelConstants[instanceID];
    float4x4 mvp = viewConstants.projectionMatrix * viewConstants.viewMatrix * instance.modelMatrix;
    
    VertexOut data;
    
    data.position = mvp * float4(vertices[vertexID].position, 1);
    data.textureCoord = vertices[vertexID].textureCoord;
    data.color = instance.color;
    
    return data;
}

constexpr sampler sampler2d(min_filter::linear, mag_filter::linear, address::repeat);

fragment half4 basic_fs
(
    VertexOut       vOut        [[ stage_in ]],
    texture2d<half> texture     [[ texture(0) ]]
)
{
    half4 color = half4(vOut.color.r, vOut.color.g, vOut.color.b, 1.0);
    
    if (!is_null_texture(texture))
    {
        color = color * texture.sample(sampler2d, vOut.textureCoord);
    }
    
    return color;
}
