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
    float4 position [[ position ]];
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

float blur(texture2d<float> occlusion, float2 texCoord);

// Fragment Shader
fragment half4 final_fragment_shader(
                                     VertexOut          data            [[ stage_in ]],
                                     texture2d<float>   albedo          [[ texture(0) ]],
                                     texture2d<float>   occlusion       [[ texture(1) ]]
                                     )
{
    sampler sampler2d;
    
    float4 color = albedo.sample(sampler2d, data.texCoord, level(0));

    float ao = blur(occlusion, data.texCoord);

    color *= ao;

    return half4(color.r, color.g, color.b, color.a);
}

float blur(texture2d<float> occlusion, float2 texCoord)
{
    sampler sampler2d;
    
    float2 texelSize = 1.0 / float2(occlusion.get_width(), occlusion.get_height());

    float result = 0.0;

    int kernelSize = 4;

    for (int x = -kernelSize; x < kernelSize; ++x)
    {
        for (int y = -kernelSize; y < kernelSize; ++y)
        {
            float2 offset = float2(float(x), float(y)) * texelSize;
            result += occlusion.sample(sampler2d, texCoord + offset).x;
        }
    }

    float size = float(kernelSize) * 2;

    return result / (size * size);
}
