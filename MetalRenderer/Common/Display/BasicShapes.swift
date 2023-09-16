//
//  BasicShapes.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 14.08.2023.
//

import Foundation
import MetalKit

final class CubeShape
{
    private var minBounds: float3 = .zero
    private var maxBounds: float3 = .one
    
    private var vertices: [BasicVertex] = []
    private var indicies: [UInt16] = []
    
    private var verticesBuffer: MTLBuffer!
    private var indiciesBuffer: MTLBuffer!
    
    init()
    {
        setup()
    }
    
    init(mins: float3, maxs: float3)
    {
        minBounds = mins
        maxBounds = maxs
        
        setup()
    }
    
    private func setup()
    {
        let center = (minBounds + maxBounds) * 0.5
        minBounds = minBounds - center
        maxBounds = maxBounds - center
        
        vertices = [
            BasicVertex(minBounds.x, minBounds.y, minBounds.z, 0, 0),  // Back     Right   Bottom      0
            BasicVertex(maxBounds.x, minBounds.y, minBounds.z, 1, 0),  // Front    Right   Bottom      1
            BasicVertex(minBounds.x, maxBounds.y, minBounds.z, 0, 1),  // Back     Left    Bottom      2
            BasicVertex(maxBounds.x, maxBounds.y, minBounds.z, 1, 1),  // Front    Left    Bottom      3
            
            BasicVertex(minBounds.x, minBounds.y, maxBounds.z, 0, 0),  // Back     Right   Top         4
            BasicVertex(maxBounds.x, minBounds.y, maxBounds.z, 1, 0),  // Front    Right   Top         5
            BasicVertex(minBounds.x, maxBounds.y, maxBounds.z, 0, 1),  // Back     Left    Top         6
            BasicVertex(maxBounds.x, maxBounds.y, maxBounds.z, 1, 0)   // Front    Left    Top         7
        ]
        
        indicies = [
            //Top
            4, 6, 5,
            5, 6, 7,
            
            //Bottom
            2, 0, 3,
            3, 0, 1,
            
            //Back
            0, 2, 4,
            4, 2, 6,
            
            //Front
            3, 1, 7,
            7, 1, 5,
            
            //Right
            1, 0, 5,
            5, 0, 4,
            
            //Left
            2, 3, 6,
            6, 3, 7,
        ]
        
        verticesBuffer = Engine.device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<BasicVertex>.stride * vertices.count,
            options: []
        )
        
        indiciesBuffer = Engine.device.makeBuffer(
            bytes: indicies,
            length: MemoryLayout<UInt16>.size * indicies.count,
            options: []
        )
    }
    
    func render(with encoder: MTLRenderCommandEncoder?)
    {
        guard verticesBuffer != nil else { return }
        
        encoder?.setVertexBuffer(verticesBuffer, offset: 0, index: 0)

        encoder?.drawIndexedPrimitives(type: .triangle,
                                       indexCount: indicies.count,
                                       indexType: .uint16,
                                       indexBuffer: indiciesBuffer,
                                       indexBufferOffset: 0)
    }
    
    func render(with encoder: MTLRenderCommandEncoder?, instanceCount: Int)
    {
        guard verticesBuffer != nil else { return }
        
        encoder?.setVertexBuffer(verticesBuffer, offset: 0, index: 0)

        encoder?.drawIndexedPrimitives(type: .triangle,
                                       indexCount: indicies.count,
                                       indexType: .uint16,
                                       indexBuffer: indiciesBuffer,
                                       indexBufferOffset: 0,
                                       instanceCount: instanceCount)
    }
}

final class QuadShape
{
    private var minBounds: float3 = .zero
    private var maxBounds: float3 = .one
    
    private var vertices: [BasicVertex] = []
    private var verticesBuffer: MTLBuffer!
    
    init()
    {
        setup()
    }
    
    init(mins: float3, maxs: float3)
    {
        minBounds = mins
        maxBounds = maxs
        
        setup()
    }
    
    private func setup()
    {
        let center = (minBounds + maxBounds) * 0.5
        minBounds = minBounds - center
        maxBounds = maxBounds - center
        
        minBounds.z = 0
        maxBounds.z = 0
        
        vertices = [
            BasicVertex(minBounds.x, minBounds.y, maxBounds.z, 0, 1),
            BasicVertex(minBounds.x, maxBounds.y, maxBounds.z, 0, 0),
            BasicVertex(maxBounds.x, minBounds.y, maxBounds.z, 1, 1),
            BasicVertex(maxBounds.x, maxBounds.y, maxBounds.z, 1, 0)
        ]
        
        verticesBuffer = Engine.device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<BasicVertex>.stride * vertices.count,
            options: []
        )
    }
    
    func render(with encoder: MTLRenderCommandEncoder)
    {
        guard verticesBuffer != nil else { return }
        
        encoder.setVertexBuffer(verticesBuffer, offset: 0, index: 0)
        
        encoder.drawPrimitives(type: .triangleStrip,
                               vertexStart: 0,
                               vertexCount: vertices.count)
    }
    
    func render(with encoder: MTLRenderCommandEncoder, instanceCount: Int)
    {
        guard verticesBuffer != nil else { return }
        
        encoder.setVertexBuffer(verticesBuffer, offset: 0, index: 0)
        
        encoder.drawPrimitives(type: .triangleStrip,
                               vertexStart: 0,
                               vertexCount: vertices.count,
                               instanceCount: instanceCount)
    }
}

private struct BasicVertex
{
    let pos: float3
    let uv: float2
    
    init(_ x: Float, _ y: Float, _ z: Float, _ u: Float, _ v: Float)
    {
        self.pos = float3(x, y, z)
        self.uv = float2(u, v)
    }
}
