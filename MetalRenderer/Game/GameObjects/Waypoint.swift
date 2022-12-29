//
//  Waypoint.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 24.12.2022.
//

import Foundation
import MetalKit

final class Waypoint
{
    var transform = Transform()
    
    var neighbors: [(Float, Int)] = []
    
    private (set) var minBounds: float3 = .zero
    private (set) var maxBounds: float3 = float3(16, 16, 16)
    
    private var _vertices: [vector_float3] = []
    private var _indicies: [UInt16] = []
    
    private var _verticesBuffer: MTLBuffer!
    private var _indiciesBuffer: MTLBuffer!
    
    private var modelConstants = ModelConstants()
    
    init()
    {
        setup()
    }
    
    func add(neighbor: Int, distance: Float)
    {
        neighbors.append((distance, neighbor))
    }
    
    private func setup()
    {
        let center = (minBounds + maxBounds) * 0.5
        minBounds = minBounds - center
        maxBounds = maxBounds - center
        
        _vertices = [
            float3(minBounds.x, maxBounds.y, maxBounds.z), //frontLeftTop       0
            float3(minBounds.x, minBounds.y, maxBounds.z), //frontLeftBottom    1
            float3(maxBounds.x, maxBounds.y, maxBounds.z), //frontRightTop      2
            float3(maxBounds.x, minBounds.y, maxBounds.z), //frontRightBottom   3
            float3(minBounds.x, maxBounds.y, minBounds.z), //backLeftTop        4
            float3(minBounds.x, minBounds.y, minBounds.z), //backLeftBottom     5
            float3(maxBounds.x, maxBounds.y, minBounds.z), //backRightTop       6
            float3(maxBounds.x, minBounds.y, minBounds.z), //backRightBottom    7
        ]
        
        _indicies = [
            0, 1,
            2, 3,
            4, 5,
            6, 7,
            
            0, 2,
            1, 3,
            4, 6,
            5, 7,
            
            0, 4,
            1, 5,
            2, 6,
            3, 7
        ]
        
        _verticesBuffer = Engine.device.makeBuffer(bytes: _vertices, length: MemoryLayout<float3>.stride * _vertices.count, options: [])
        _indiciesBuffer = Engine.device.makeBuffer(bytes: _indicies, length: MemoryLayout<UInt16>.size * _indicies.count, options: [])
    }
    
    func render(with encoder: MTLRenderCommandEncoder?)
    {
        guard _verticesBuffer != nil else { return }
        
        encoder?.setVertexBuffer(_verticesBuffer, offset: 0, index: 0)

        encoder?.drawIndexedPrimitives(type: .line,
                                       indexCount: _indicies.count,
                                       indexType: .uint16,
                                       indexBuffer: _indiciesBuffer,
                                       indexBufferOffset: 0)
    }
}

