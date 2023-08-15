//
//  Skybox.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 04.02.2022.
//

import MetalKit

class Skybox
{
    private let vertexCount: Int
    private let vertexBuffer: MTLBuffer
    private let texture: MTLTexture
    
    init()
    {
        let A = float3(-1.0,  1.0,  1.0)
        let B = float3(-1.0,  1.0, -1.0)
        let C = float3( 1.0,  1.0, -1.0)
        let D = float3( 1.0,  1.0,  1.0)
        let Q = float3(-1.0, -1.0,  1.0)
        let R = float3( 1.0, -1.0,  1.0)
        let S = float3(-1.0, -1.0, -1.0)
        let T = float3( 1.0, -1.0, -1.0)
        
        let vertices: [float3] = [
            A,B,C, A,C,D,   //Front
            R,T,S, Q,R,S,   //Back
            
            Q,S,B, Q,B,A,   //Left
            D,C,T, D,T,R,   //Right
            
            Q,A,D, Q,D,R,   //Top
            B,S,T, B,T,C    //Bot
        ]
        
        vertexCount = vertices.count
        vertexBuffer = Engine.device.makeBuffer(bytes: vertices, length: vertexCount * float3.stride)!
        texture = TextureManager.shared.loadCubeTexture(imageName: "night-sky")!
    }
    
    func renderWithEncoder(_ encoder: MTLRenderCommandEncoder)
    {
        encoder.setFragmentTexture(texture, index: 0)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
    }
}
