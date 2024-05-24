//
//  Editor.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 24.05.2024.
//

#include <metal_stdlib>
#include "Common.metal"
using namespace metal;

struct VertexIn
{
    float3 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

struct VertexOut
{
    float pointSize [[ point_size ]];
    float4 position [[ position ]];
    float4 color;
};

vertex VertexOut editor_dot_vs(constant VertexIn       *vertices       [[ buffer(0) ]],
                               constant SceneConstants &viewConstants  [[ buffer(1) ]],
                               constant ModelConstants &modelConstants [[ buffer(2) ]],
                               uint                    vertexID        [[ vertex_id ]])
{
    float4x4 mvp = viewConstants.projectionMatrix * viewConstants.viewMatrix * modelConstants.modelMatrix;
    
    VertexOut data;
    
    data.position = mvp * float4(vertices[vertexID].position, 1);
    data.color = vertices[vertexID].color;
    data.pointSize = 10;
    
    return data;
}

fragment float4 editor_dot_fs(VertexOut in [[ stage_in ]] )
{
    return float4(in.color);
}



