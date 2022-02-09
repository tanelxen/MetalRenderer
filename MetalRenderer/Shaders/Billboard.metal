//
//  Billboard.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 06.02.2022.
//

#include <metal_stdlib>
#include "Common.metal"
using namespace metal;


vertex float4 billboard_vertex_shader(const Vertex              vIn             [[ stage_in ]],
                                      constant SceneConstants   &viewConstants  [[ buffer(1) ]],
                                      constant ModelConstants   &modelConstants [[ buffer(2) ]])
{
    float4 position = vIn.position;
    
    float4x4 vMatrix = viewConstants.viewMatrix;
    float3 cameraRight = float3(vMatrix[0][0], vMatrix[1][0], vMatrix[2][0]);
    float3 cameraUp = float3(vMatrix[0][1], vMatrix[1][1], vMatrix[2][1]);
    
    float width = 0.5;
    float height = 0.5;

    float3 vertexPosition_worldspace = cameraRight * position.x * width + cameraUp * position.y * height;

    return viewConstants.projectionMatrix * viewConstants.viewMatrix * modelConstants.modelMatrix * float4(vertexPosition_worldspace, 1);
}

fragment half4 billboard_fragment_shader()
{
    return half4(1.0, 0.0, 0.0, 1.0);
}


