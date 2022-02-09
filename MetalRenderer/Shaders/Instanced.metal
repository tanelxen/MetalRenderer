//
//  Instanced.metal
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 18.01.2022.
//

#include <metal_stdlib>
#include "Common.metal"
using namespace metal;

//// Vertex Shader
//vertex RasterizerData instanced_vertex_shader(
//                                              const Vertex              vIn             [[ stage_in ]],
//                                              constant SceneConstants   &viewConstants  [[ buffer(1) ]],
//                                              constant ModelConstants   *modelConstants [[ buffer(2) ]],
//                                              uint instanceId [[ instance_id ]]
//                                              )
//{
//    ModelConstants modelConstant = modelConstants[instanceId];
//    
//    float4x4 mvp = viewConstants.projectionMatrix * viewConstants.viewMatrix * modelConstant.modelMatrix;
//    
//    float4 worldPosition = modelConstant.modelMatrix * float4(vIn.position, 1);
//    
//    RasterizerData data;
//    
//    data.position = mvp * float4(vIn.position, 1);
//    data.uv = vIn.uv;
//    
//    data.worldPosition = worldPosition;
//    
//    data.surfaceNormal = normalize(modelConstant.modelMatrix * float4(vIn.normal, 0.0)).xyz;
//    data.surfaceTangent = normalize(modelConstant.modelMatrix * float4(vIn.tangent, 0.0)).xyz;
//    data.surfaceBitangent = normalize(modelConstant.modelMatrix * float4(cross(vIn.normal, vIn.tangent), 0.0)).xyz;
//    
//    return data;
//}


