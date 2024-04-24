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
//    float3 normal [[attribute(1)]];
    float2 uv [[attribute(2)]];
};

struct VertexOut
{
    float4 position [[ position ]];
    float4 viewPosition;
    float3 normal;
    float2 uv;
    float4 color;
    float3 light;
};

vertex VertexOut brush_vs(constant VertexIn       *vertices       [[ buffer(0) ]],
                          constant SceneConstants &viewConstants  [[ buffer(1) ]],
                          constant ModelConstants &modelConstants [[ buffer(2) ]],
                          uint                    vertexID        [[ vertex_id ]])
{
    float4x4 mvp = viewConstants.projectionMatrix * viewConstants.viewMatrix * modelConstants.modelMatrix;
    
    VertexOut data;
    
    data.position = mvp * float4(vertices[vertexID].position, 1);
    
    data.viewPosition = viewConstants.viewMatrix * float4(vertices[vertexID].position, 1);
    
//    data.normal = vertices[vertexID].normal;
    data.uv = vertices[vertexID].uv;
    data.color = modelConstants.color;
    
    float4x4 mv = viewConstants.viewMatrix * modelConstants.modelMatrix;
    
    data.light = -normalize(mv * float4(vertices[vertexID].position, 1)).xyz;
    
    return data;
}

//constexpr sampler sampler2d(min_filter::linear, mag_filter::linear, address::repeat);

fragment float4 brush_fs(VertexOut in [[ stage_in ]])
{
//    float4 color = in.color;
    
    float3 xTangent = dfdx( in.viewPosition.xyz );
    float3 yTangent = dfdy( in.viewPosition.xyz );
    float3 faceNormal = normalize( cross( yTangent, xTangent ) );
    
    float nDotL = dot(faceNormal, in.light);
    
    return float4(nDotL, nDotL, nDotL, 1.0) * in.color;
}
