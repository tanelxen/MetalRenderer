//
//  SimpleQuad.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

class SimpleQuad
{
    var vertexBuffer: MTLBuffer!
    
    private struct Vertex
    {
        let position: float3
        let texCoord: float2
    }
    
    private let vertices: [Float] = [
        -1, 1, 0, 0, 0,     //Top Left
        -1,-1, 0, 0, 1,     //Bottom Left
         1,-1, 0, 1, 1,     //Bottom Right
        
        -1, 1, 0, 0, 0,     //Top Left
         1,-1, 0, 1, 1,     //Bottom Right
         1, 1, 0, 1, 0      //Top Right
    ]
    
    init()
    {
        vertexBuffer = Engine.device.makeBuffer(bytes: vertices, length: MemoryLayout<Float>.stride * vertices.count, options: [])
    }
    
    func drawPrimitives(with encoder: MTLRenderCommandEncoder?)
    {
        encoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
    }
}
