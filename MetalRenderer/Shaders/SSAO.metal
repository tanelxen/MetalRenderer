//
//  SSAO.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 20.01.2022.
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
vertex VertexOut ssao_vertex_shader(const device VertexIn *vIn [[ buffer(0) ]], unsigned int vertexId [[ vertex_id ]])
{
    VertexOut out;
    
    VertexIn curVertex = vIn[vertexId];
    
    out.position = float4(curVertex.position, 1);
    out.texCoord = curVertex.texCoord;
    
    return out;
}

struct FragData
{
    float3 position;
    float3 normal;
    float3 noise;
};

// Fragment Shader
fragment half ssao_fragment_shader(
                                     VertexOut          data            [[ stage_in ]],
                                     constant float4x4  &projection     [[ buffer(1) ]],
                                     texture2d<float>   normal          [[ texture(0) ]],
                                     texture2d<float>   position        [[ texture(1) ]],
                                     texture2d<float>   kernelTexure    [[ texture(2) ]],
                                     texture2d<float>   noise           [[ texture(3) ]]
                                     )
{
    sampler sampler2d;
    constexpr sampler samplerRepeat(address::repeat);
    
    int KernelSize = 8;
    float2 NoiseScale = float2(800.0/4.0, 600.0/4.0);
    float radius = 0.5;
    float bias = 0.025;

    FragData frag;

    frag.position = position.sample(sampler2d, data.texCoord).xyz;
    frag.normal = normalize(normal.sample(sampler2d, data.texCoord).xyz);
    frag.noise = normalize(noise.sample(samplerRepeat, data.texCoord * NoiseScale).xyz);

    // TBN matrix
    float3 tangent = normalize(frag.noise - frag.normal * dot(frag.noise, frag.normal));
    float3 bitangent = cross(frag.normal, tangent);
    float3x3 TBN = float3x3(tangent, bitangent, frag.normal);

    float occlusion = 0.0f;

    for(int i = 0; i < KernelSize; i++)
    {
        float x = float(i) / float(KernelSize);

        for(int j = 0; j < KernelSize; j++)
        {
            float y = float(j) / float(KernelSize);

            float3 mySample = TBN * kernelTexure.sample(sampler2d, float2(x, y)).xyz;
            mySample = frag.position + mySample * radius;

            float4 offset = float4(mySample, 1.0f);
            offset = projection * offset;
            offset.xyz /= offset.w;
            offset.xyz = offset.xyz * 0.5f + 0.5f;

            float depth = position.sample(sampler2d, offset.xy).z;

            float range = smoothstep(0.0f, 1.0f, radius / abs(frag.position.z - depth));
            occlusion += ((depth >= mySample.z + bias) ? 1.0f : 0.0f) * range;
        }
    }

    occlusion = pow(1.0f - (occlusion / float(KernelSize * KernelSize)), 5);

    return occlusion;
}



// Vertex Shader
vertex VertexOut ssao_blur_vertex_shader(const device VertexIn *vIn [[ buffer(0) ]], unsigned int vertexId [[ vertex_id ]])
{
    VertexOut out;
    
    VertexIn curVertex = vIn[vertexId];
    
    out.position = float4(curVertex.position, 1);
    out.texCoord = curVertex.texCoord;
    
    return out;
}

// Fragment Shader
fragment half ssao_blur_fragment_shader(
                                     VertexOut          data            [[ stage_in ]],
                                     texture2d<float>   occlusion       [[ texture(0) ]]
                                     )
{
    sampler sampler2d;
    
    float2 texelSize = 1.0 / float2(occlusion.get_width(), occlusion.get_height());

    float result = 0.0;

    int kernelSize = 3;

    for (int x = -kernelSize; x < kernelSize; ++x)
    {
        for (int y = -kernelSize; y < kernelSize; ++y)
        {
            float2 offset = float2(float(x), float(y)) * texelSize;
            result += occlusion.sample(sampler2d, data.texCoord + offset).x;
        }
    }

    float size = float(kernelSize) * 2;

    return result / (size * size);
}
