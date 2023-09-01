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
    
    private var vertices: [float3] = []
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
            float3(minBounds.x, minBounds.y, minBounds.z),  // Back     Right   Bottom      0
            float3(maxBounds.x, minBounds.y, minBounds.z),  // Front    Right   Bottom      1
            float3(minBounds.x, maxBounds.y, minBounds.z),  // Back     Left    Bottom      2
            float3(maxBounds.x, maxBounds.y, minBounds.z),  // Front    Left    Bottom      3
            
            float3(minBounds.x, minBounds.y, maxBounds.z),  // Back     Right   Top         4
            float3(maxBounds.x, minBounds.y, maxBounds.z),  // Front    Right   Top         5
            float3(minBounds.x, maxBounds.y, maxBounds.z),  // Back     Left    Top         6
            float3(maxBounds.x, maxBounds.y, maxBounds.z)   // Front    Left    Top         7
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
            length: MemoryLayout<float3>.stride * vertices.count,
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
