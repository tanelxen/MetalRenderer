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

fragment half4 solid_color_fs(VertexOut vOut [[ stage_in ]])
{
    return half4(vOut.color.r, vOut.color.g, vOut.color.b, 0.3);
}
