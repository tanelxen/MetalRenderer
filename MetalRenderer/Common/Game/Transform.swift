//
//  Transform.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 15.01.2022.
//

import simd

class Transform
{
    var position: float3
    var rotation: Rotator
    var scale: float3
    
    static let zero: Transform = Transform()
    
    private var _matrix: matrix_float4x4 = matrix_identity_float4x4
    
    var matrix: matrix_float4x4 { _matrix }
    
    init(position: float3 = .zero, rotation: Rotator = .zero, scale: float3 = .one)
    {
        self.position = position
        self.rotation = rotation
        self.scale = scale
    }
    
    func updateModelMatrix()
    {
        let R = matrix_float4x4(rotation.orientation)
        let T = matrix_float4x4(translation: position)
        
        _matrix = simd_mul(T, R)
        _matrix.scale(axis: scale)
    }
}
