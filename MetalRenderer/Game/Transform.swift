//
//  Transform.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 15.01.2022.
//

import simd

class Transform
{
    var position: float3 = .zero
    var rotation: Rotator = .zero
    var scale: float3 = .one
    
    static let zero: Transform = Transform()
    
    var parent = matrix_identity_float4x4
    
    private var _matrix: matrix_float4x4 = matrix_identity_float4x4
    
    var matrix: matrix_float4x4 { _matrix }
    
    func updateModelMatrix()
    {
        _matrix = parent
        
        _matrix.translate(direction: position)
        
        _matrix = _matrix * rotation.matrix
        
        _matrix.scale(axis: scale)
    }
}
