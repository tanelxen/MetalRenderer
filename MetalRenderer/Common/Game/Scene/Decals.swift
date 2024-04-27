//
//  Decals.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 14.09.2023.
//

import Metal
import simd

final class Decals
{
    private class Decal
    {
        var modelMatrix = matrix_identity_float4x4
        var lifespan: Float = 100.0
        let color: float4 = float4(1, 1, 1, 1)
    }
    
    private var decals: [Decal] = []
    
    private let quadShape = QuadShape(mins: .zero, maxs: .one)
    
    static let shared = Decals()
    
    private let maxCount = 1000
    
    private var constantsBuffer: MTLBuffer!
    private var texture: MTLTexture!
    
    init()
    {
        constantsBuffer = Engine.device.makeBuffer(length: MemoryLayout<ModelConstants>.stride * maxCount)
        texture = TextureManager.shared.getTexture(for: "Assets/bullet_hole.png")
    }
    
    func addDecale(origin: float3, normal: float3)
    {
        let decal = Decal()
        
        let triangleNormal = float3(0.0, 0.0, 1.0)
        let planeNormal = normal
        
        let offset = normal * 0.8
        decal.modelMatrix.translate(direction: origin + offset)
        
        let dot = dot(triangleNormal, planeNormal)
        
        if dot == -1
        {
            let rotationAxis = float3(1.0, 0.0, 0.0) // Ось X
            let angle = Float.pi // 180 градусов
            
            decal.modelMatrix.rotate(angle: angle, axis: rotationAxis)
        }
        else if dot != 1
        {
            let rotationAxis = normalize(cross(triangleNormal, planeNormal))
            let angle = acos(dot)
            
            decal.modelMatrix.rotate(angle: angle, axis: rotationAxis)
        }
        
        decal.modelMatrix.scale(axis: float3(repeating: 10))
        
        decals.append(decal)
    }
    
    func update()
    {
        let dt = GameTime.deltaTime
        
        decals.removeAll(where: { $0.lifespan <= 0 })

        for decale in decals
        {
            decale.lifespan -= dt
        }
    }
    
    func render(with encoder: MTLRenderCommandEncoder)
    {
        guard !decals.isEmpty else { return }
        
        var pointer = constantsBuffer.contents().bindMemory(to: ModelConstants.self, capacity: maxCount)
        
        var count: Int = 0
        
        for decale in decals
        {
            guard decale.lifespan > 0 else { continue }
            
            var modelConstants = ModelConstants()
            modelConstants.modelMatrix = decale.modelMatrix
            modelConstants.color = decale.color

            pointer.pointee = modelConstants
            pointer = pointer.advanced(by: 1)
            
            count += 1
        }
        
        if count > 0
        {
            encoder.setVertexBuffer(constantsBuffer, offset: 0, index: 2)
            encoder.setFragmentTexture(texture, index: 0)
            quadShape.render(with: encoder, instanceCount: count)
        }
    }
}
