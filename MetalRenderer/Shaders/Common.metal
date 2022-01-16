//
//  Common.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex
{
    float3 position [[ attribute(0) ]];
    float3 normal   [[ attribute(1) ]];
    float2 uv       [[ attribute(2) ]];
};

struct RasterizerData
{
    float4 position [[ position ]];
    float2 uv;
    
    float3 worldPosition;
    float3 surfaceNormal;
    
    float3 eyeVector;
};

struct SceneConstants
{
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float3 cameraPosition;
};

struct ModelConstants
{
    float4x4 modelMatrix;
};

struct Material
{
    bool useColor;
    bool useTexture;
    bool isLit;
    
    float4 color;
    float3 ambient;
    float3 diffuse;
};

struct LightData
{
    float3 position;
    float3 color;
    float brightness;
    
    float ambientIntensity;
    float diffuseIntensity;
};
