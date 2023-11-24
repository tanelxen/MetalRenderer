//
//  Billboards.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 09.10.2023.
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
    half4 color;
};

vertex VertexOut billboard_vs(constant VertexIn          *vertices       [[ buffer(0) ]],
                              constant SceneConstants    &viewConstants  [[ buffer(1) ]],
                              constant ModelConstants    *modelConstants [[ buffer(2) ]],
                              uint                       vertexID        [[ vertex_id ]],
                              uint                       instanceID      [[ instance_id ]])
{
    ModelConstants instance = modelConstants[instanceID];
    
    float4x4 modelView = viewConstants.viewMatrix * instance.modelMatrix;
    
    modelView[0][0] = instance.modelMatrix[0][0];
    modelView[0][1] = 0;
    modelView[0][2] = 0;
    
    modelView[1][0] = 0;
    modelView[1][1] = instance.modelMatrix[1][1];
    modelView[1][2] = 0;
    
    modelView[2][0] = 0;
    modelView[2][1] = 0;
    modelView[2][2] = 1;
    
    float4x4 mvp = viewConstants.projectionMatrix * modelView;
    
    VertexOut data;
    
    data.position = mvp * float4(vertices[vertexID].position, 1);
    data.textureCoord = vertices[vertexID].textureCoord;
    
    float4 color = instance.color;
    data.color = half4(color);
    
    return data;
}

constexpr sampler sampler2d(min_filter::linear, mag_filter::linear, address::repeat);

fragment half4 billboard_fs
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



