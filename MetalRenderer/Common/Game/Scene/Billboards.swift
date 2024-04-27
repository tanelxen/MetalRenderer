//
//  Billboards.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 09.10.2023.
//

import Metal
import simd

final class Billboards
{
    private struct Batch
    {
        let texture: MTLTexture!
        let buffer: MTLBuffer!
        var count: Int = 0
    }

    private var batches: [String: Batch] = [:]
    
    private let quadShape = QuadShape(mins: .zero, maxs: .one)
    
    static let shared = Billboards()
    
    private let maxCount = 1000
    
    func addBillboard(origin: float3, image: String)
    {
        var modelMatrix = matrix_identity_float4x4
        modelMatrix.translate(direction: origin)
        modelMatrix.scale(axis: float3(repeating: 20))
        
        var modelConstants = ModelConstants()
        modelConstants.modelMatrix = modelMatrix
        
        if batches[image] == nil
        {
            let texture = TextureManager.shared.getTexture(for: image)
            let buffer = Engine.device.makeBuffer(length: MemoryLayout<ModelConstants>.stride * maxCount, options: [])
            
            batches[image] = Batch(texture: texture, buffer: buffer, count: 0)
        }
        
        let count = batches[image]!.count
        
        var pointer = batches[image]!.buffer.contents().bindMemory(to: ModelConstants.self, capacity: maxCount)
        pointer = pointer.advanced(by: count)
        
        pointer.pointee = modelConstants
        
        batches[image]!.count = count + 1
    }
    
    func render(with encoder: MTLRenderCommandEncoder)
    {
        for (_, batch) in batches
        {
            guard batch.count > 0 else { continue }
            
            encoder.setVertexBuffer(batch.buffer, offset: 0, index: 2)
            encoder.setFragmentTexture(batch.texture, index: 0)
            quadShape.render(with: encoder, instanceCount: batch.count)
        }
    }
}

