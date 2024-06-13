//
//  Uniforms.h
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 27.04.2024.
//

#ifndef Uniforms_h
#define Uniforms_h

#include <simd/simd.h>

typedef struct
{
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
    vector_float2 viewportSize;
    int viewType;
} SceneConstants;

typedef struct
{
    matrix_float4x4 modelMatrix;
    vector_float4 color;
    int useFlatShading;
} ModelConstants;

#endif /* Uniforms_h */
