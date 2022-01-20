//
//  Final.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 19.01.2022.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn
{
    packed_float3 position;
    packed_float2 texCoord;
};

struct VertexOut
{
    float4 position     [[ position ]];
    float2 texCoord;
};

// Vertex Shader
vertex VertexOut final_vertex_shader(const device VertexIn *vIn [[ buffer(0) ]], unsigned int vertexId [[ vertex_id ]])
{
    VertexOut out;
    
    VertexIn curVertex = vIn[vertexId];
    
    out.position = float4(curVertex.position, 1);
    out.texCoord = curVertex.texCoord;
    
    return out;
}

// Fragment Shader
fragment half4 final_fragment_shader(
                                     VertexOut          data            [[ stage_in ]],
                                     texture2d<float>   albedo          [[ texture(0) ]],
                                     texture2d<float>   occlusion       [[ texture(1) ]]
                                     )
{
    sampler sampler2d;
    
    float4 color = albedo.sample(sampler2d, data.texCoord, level(0));
    float ao = occlusion.sample(sampler2d, data.texCoord, level(0)).x;

    color *= ao;

    return half4(color.r, color.g, color.b, color.a);
}
