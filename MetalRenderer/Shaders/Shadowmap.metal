//
//  Shadowmap.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 01.02.2022.
//

#include <metal_stdlib>
#include "Common.metal"
using namespace metal;

struct VertexOut
{
    float3 worldPos;
    float4 position     [[ position ]];
    uint layer          [[render_target_array_index]];
};

vertex VertexOut shadowmap_vertex_shader(const Vertex               vIn                 [[ stage_in ]],
                                         constant float4x4          &projectionMatrix   [[ buffer(1) ]],
                                         constant ModelConstants    &modelConstants     [[ buffer(2) ]],
                                         constant uint              &sideIndex          [[ buffer(3) ]])
{
    VertexOut out;
    
    float4 worldPos = modelConstants.modelMatrix * vIn.position;
    
    out.worldPos = worldPos.xyz;
    out.position = projectionMatrix * worldPos;
    out.layer = sideIndex;
    
    return out;
}

struct FragOut
{
//    half color [[ color(0) ]];
    float depth [[ depth(any) ]];
};

fragment FragOut shadowmap_fragment_shader(VertexOut            in      [[ stage_in ]],
                                           constant LightData   &light  [[ buffer(0) ]])
{
    float lightDistance = length(in.worldPos - light.position);
    
    float far_plane = light.radius;
    
    // преобразование к интервалу [0, 1] посредством деления на far_plane
    lightDistance /= far_plane;
    
    FragOut out;
    
//    out.color = lightDistance;
    out.depth = lightDistance;
    
    return out;
}
