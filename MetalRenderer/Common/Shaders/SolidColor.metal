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
    float4 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

struct VertexOut
{
    float4 position [[ position ]];
    float3 color;
};

vertex VertexOut solid_color_vs(constant float3           *vertices       [[ buffer(0) ]],
                                constant SceneConstants   &viewConstants  [[ buffer(1) ]],
                                constant ModelConstants   &modelConstants [[ buffer(2) ]],
                                uint                      vertexID        [[ vertex_id ]])
{
    float4x4 mvp = viewConstants.projectionMatrix * viewConstants.viewMatrix * modelConstants.modelMatrix;
    
    VertexOut data;
    
    data.position = mvp * float4(vertices[vertexID], 1);
    data.color = modelConstants.color;
    
    return data;
}

vertex VertexOut solid_color_inst_vs(constant float3           *vertices       [[ buffer(0) ]],
                                     constant SceneConstants   &viewConstants  [[ buffer(1) ]],
                                     constant ModelConstants   *modelConstants [[ buffer(2) ]],
                                     uint                      vertexID        [[ vertex_id ]],
                                     uint                      instanceID      [[ instance_id ]])
{
    ModelConstants instance = modelConstants[instanceID];
    float4x4 mvp = viewConstants.projectionMatrix * viewConstants.viewMatrix * instance.modelMatrix;
    
    VertexOut data;
    
    data.position = mvp * float4(vertices[vertexID], 1);
    data.color = instance.color;
    
    return data;
}

vertex VertexOut ui_vs(constant float2      *vertices           [[ buffer(0) ]],
                       constant float4x4    &projectionMatrix   [[ buffer(1) ]],
                       uint                 vertexID            [[ vertex_id ]])
{
    VertexOut data;
    
    data.position = projectionMatrix * float4(vertices[vertexID], 0, 1);
    data.color = float3(1, 1, 1);
    
    return data;
}

fragment half4 solid_color_fs(VertexOut vOut [[ stage_in ]])
{
    return half4(vOut.color.r, vOut.color.g, vOut.color.b, 1.0);
}
