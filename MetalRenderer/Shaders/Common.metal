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
    float4 position [[attribute(0)]];
    float4 normal [[attribute(1)]];
    float4 color [[attribute(2)]];
    float2 textureCoord [[attribute(3)]];
    float2 lightmapCoord [[attribute(4)]];
};

struct RasterizerData
{
    float4 position [[ position ]];
    float2 uv;
    float2 lmUV;
    float4 color;
    
    float4 worldPosition;
    float3 surfaceNormal;
    float3 surfaceTangent;
    float3 surfaceBitangent;
};

struct SceneConstants
{
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float4x4 skyViewMatrix;
    float3 cameraPosition;
};

struct ShadowConstants
{
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
};

struct ModelConstants
{
    float4x4 modelMatrix;
    float3 color;
};

struct MaterialConstants
{
    bool isLit;
    bool useBaseColorMap;
    bool useNormalMap;
    bool useLightmap;
    
    float4 color;
    float3 ambient;
    float3 diffuse;
    float3 specular;
    float shininess;
};

struct LightData
{
    float3 position;
    float3 color;
    float radius;
    
    float ambientIntensity;
    float diffuseIntensity;
};
