//
//  Blur.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 22.01.2022.
//

#include <metal_stdlib>
using namespace metal;

float3 blur(texture2d<float> texture, float2 texCoord)
{
    sampler sampler2d;
    
    float2 texelSize = 1.0 / float2(texture.get_width(), texture.get_height());

    float3 result = 0.0;

    const int kernelSize = 2;

    for (int x = -kernelSize; x < kernelSize; ++x)
    {
        for (int y = -kernelSize; y < kernelSize; ++y)
        {
            float2 offset = float2(float(x), float(y)) * texelSize;
            result += texture.sample(sampler2d, texCoord + offset).rgb;
        }
    }

    float size = float(kernelSize) * 2;

    return result / (size * size);
}
