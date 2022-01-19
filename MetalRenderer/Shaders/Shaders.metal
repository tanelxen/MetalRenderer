//
//  Shaders.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 11.01.2022.
//

#include "Common.metal"

#include <metal_stdlib>
using namespace metal;

// Vertex Shader
vertex RasterizerData basic_vertex_shader(
                                          const Vertex              vIn             [[ stage_in ]],
                                          constant SceneConstants   &viewConstants  [[ buffer(1) ]],
                                          constant ModelConstants   &modelConstants [[ buffer(2) ]]
                                          )
{
    float4x4 mvp = viewConstants.projectionMatrix * viewConstants.viewMatrix * modelConstants.modelMatrix;
    
    float4 worldPosition = modelConstants.modelMatrix * float4(vIn.position, 1);
    
    RasterizerData data;
    
    data.position = mvp * float4(vIn.position, 1);
    data.uv = vIn.uv;
    
    data.worldPosition = worldPosition.xyz;
    
    data.surfaceNormal = normalize(modelConstants.modelMatrix * float4(vIn.normal, 0.0)).xyz;
    data.surfaceTangent = normalize(modelConstants.modelMatrix * float4(vIn.tangent, 0.0)).xyz;
    data.surfaceBitangent = normalize(modelConstants.modelMatrix * float4(cross(vIn.normal, vIn.tangent), 0.0)).xyz;
    
    
    data.eyeVector = normalize(viewConstants.cameraPosition - data.worldPosition);
    
    return data;
}

struct FragOut
{
    half4 color0 [[ color(0) ]];
    half4 color1 [[ color(1) ]];
    half4 color2 [[ color(2) ]];
};

// Fragment Shader
fragment FragOut basic_fragment_shader(
                                       RasterizerData                     data            [[ stage_in ]],
                                       constant MaterialConstants         &material       [[ buffer(1) ]],
                                       constant LightData                 *lights         [[ buffer(2) ]],
                                       constant int                       &lightCount     [[ buffer(3) ]],
                                       sampler                            sampler2d       [[ sampler(0) ]],
                                       texture2d<float>                   baseColorMap    [[ texture(0) ]],
                                       texture2d<float>                   normalMap       [[ texture(1) ]]
                                       )
{
    float4 color = material.color;
    
//    constexpr sampler sampler2d(filter::linear, address::repeat);
    
    if (material.useBaseColorMap)
    {
        color = baseColorMap.sample(sampler2d, data.uv);
    }
    
    float3 N = normalize(data.surfaceNormal);
    
    if (material.isLit)
    {
        if (material.useNormalMap)
        {
            float3 sampleNormal = normalMap.sample(sampler2d, data.uv).rgb * 2 - 1;

            float3x3 TBN = { data.surfaceTangent, data.surfaceBitangent, data.surfaceNormal };

            N = TBN * sampleNormal;
        }

        float3 totalAmbient = float3(0, 0, 0);
        float3 totalDiffuse = float3(0, 0, 0);

        for (int i = 0; i < lightCount; i++)
        {
            LightData light = lights[i];

            float3 ambientness = material.ambient * light.ambientIntensity;
            float3 ambientColor = ambientness * light.color * light.brightness;
            totalAmbient += clamp(ambientColor, 0.0, 1.0);

            // Освещение по Ламберту в качестве диффузного освещения
            float3 L = normalize(light.position - data.worldPosition);
            float lambertComponent = max(dot(N, L), 0.0);
            float3 diffusiness = material.diffuse * light.diffuseIntensity;
            float3 diffuseLight = diffusiness * lambertComponent * light.color * light.brightness;

            float shininess = 30;

            // Блики
            float specular = pow(max(dot(reflect(-L, N), data.eyeVector), 0.0), shininess);
            float3 specularLight = light.color * specular;

            totalDiffuse += diffuseLight + specularLight;
        }

        float3 phongIntensity = clamp(totalAmbient + totalDiffuse, 0.0, 1.0);

        color *= float4(phongIntensity, 1.0);
    }
    
    FragOut out;
    
    out.color0 = half4(color.r, color.g, color.b, color.a);
    out.color1 = half4(N.x, N.y, N.z, 1.0);
    out.color2 = half4(data.worldPosition.x, data.worldPosition.y, data.worldPosition.z, 1.0);
    
    return out;
}
