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
    float3 normal [[attribute(1)]];
    float4 color [[attribute(2)]];
    float2 uv [[attribute(3)]];
};

struct VertexOut
{
    float4 position [[ position ]];
    float4 color;
    float2 uv;
    float shade [[ flat ]];
    float pointSize [[ point_size ]];
};

constant float lightaxis[3] = {0.6f, 0.8f, 1.0f};

float shadeForNormal(float3 normal)
{
    int i;
    float f;
    
    // axial plane
    for ( i = 0; i < 3; i++ ) {
        if (fabs(normal[i]) > 0.9) {
            f = lightaxis[i];
            return f;
        }
    }
    
    // between two axial planes
    for (i = 0; i < 3; i++) {
        if (fabs(normal[i]) < 0.1) {
            f = ( lightaxis[( i + 1 ) % 3] + lightaxis[( i + 2 ) % 3] ) / 2;
            return f;
        }
    }
    
    // other
    f = ( lightaxis[0] + lightaxis[1] + lightaxis[2] ) / 3;
    return f;
}

vertex VertexOut brush_vs(constant VertexIn       *vertices       [[ buffer(0) ]],
                          constant SceneConstants &viewConstants  [[ buffer(1) ]],
                          constant ModelConstants &modelConstants [[ buffer(2) ]],
                          uint                    vertexID        [[ vertex_id ]])
{
    float4x4 mvp = viewConstants.projectionMatrix * viewConstants.viewMatrix * modelConstants.modelMatrix;
    
    VertexOut data;
    
    data.position = mvp * float4(vertices[vertexID].position, 1);
    data.uv = vertices[vertexID].uv;
    data.color = vertices[vertexID].color;
    data.shade = shadeForNormal(vertices[vertexID].normal);
    data.pointSize = 10;
    
    return data;
}

constexpr sampler sampler2d(min_filter::linear, mag_filter::linear, address::repeat);

fragment float4 brush_fs(VertexOut in [[ stage_in ]], texture2d<half> albedoMap [[ texture(0) ]])
{
    float4 albedo = in.color;
    
    if (!is_null_texture(albedoMap))
    {
        albedo = float4(albedoMap.sample(sampler2d, in.uv)) * in.color;
    }
    
    float3 shade = float3(in.shade);
    return float4(shade, 1.0) * float4(albedo);
}


struct BoxVertexIn
{
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 uv [[attribute(2)]];
};

vertex VertexOut box_vs(BoxVertexIn       vIn       [[ stage_in ]],
                        constant SceneConstants &viewConstants  [[ buffer(1) ]],
                        constant ModelConstants &modelConstants [[ buffer(2) ]])
{
    float4x4 mvp = viewConstants.projectionMatrix * viewConstants.viewMatrix * modelConstants.modelMatrix;
    
    VertexOut data;
    
    data.position = mvp * float4(vIn.position, 1);
    data.uv = vIn.uv;
    data.color = modelConstants.color;
    data.shade = 1;
    
    if (modelConstants.useFlatShading)
    {
        data.shade = shadeForNormal(vIn.normal);
    }
    
    return data;
}
