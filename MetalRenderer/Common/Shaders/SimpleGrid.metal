//
//  SimpleGrid.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 23.04.2024.
//

#include <metal_stdlib>
#include "Common.metal"
using namespace metal;

struct VertexIn
{
    float3 position [[attribute(0)]];
    float2 uv [[attribute(1)]];
};

struct VertexOut
{
    float4 position [[ position ]];
    float2 uv;
};

vertex VertexOut simple_grid_vs(constant VertexIn       *vertices       [[ buffer(0) ]],
                                constant SceneConstants &viewConstants  [[ buffer(1) ]],
                                constant ModelConstants &modelConstants [[ buffer(2) ]],
                                uint                    vertexID        [[ vertex_id ]])
{
    float4x4 mvp = viewConstants.projectionMatrix * viewConstants.viewMatrix * modelConstants.modelMatrix;
    
    VertexOut data;
    
    data.position = mvp * float4(vertices[vertexID].position, 1);
    data.uv = vertices[vertexID].position.xy;
    
    return data;
}

// https://asliceofrendering.com/scene%20helper/2020/01/05/InfiniteGrid
float4 grid(float2 uv, float scale, float intensity, bool axis)
{
    float2 coord = uv / scale;
    float2 derivative = fwidth(coord);
    float2 grid = abs(fract(coord - 0.5) - 0.5) / derivative;
    
    float line = min(grid.x, grid.y);
    float minimumz = min(derivative.y, 1.0) * scale;
    float minimumx = min(derivative.x, 1.0) * scale;
    
    float4 color = float4(intensity, intensity, intensity, 1.0 - min(line, 1.0));
    
    if (axis)
    {
        // z axis
        if(uv.x > -1 * minimumx && uv.x < 1 * minimumx) {
            color = float4(0.0, 0.0, 1.0, 1.0);
        }
        // x axis
        if(uv.y > -1 * minimumz && uv.y < 1 * minimumz) {
            color = float4(1.0, 0.0, 0.0, 1.0);
        }
    }
    
    return color;
}

fragment float4 simple_grid_fs(VertexOut in [[stage_in]])
{
    float4 main = grid(in.uv, 16, 0.1, false);
    float4 second = grid(in.uv, 64, 0.4, true);
    
    return mix(main, second, 0.5);
}