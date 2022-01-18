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
    var rotation: float3 = .zero
    var scale: float3 = .one
    
    var parent = matrix_identity_float4x4
    
    private var _matrix: matrix_float4x4 = matrix_identity_float4x4
    
    var matrix: matrix_float4x4 { _matrix }
    
    func updateModelMatrix()
    {
        _matrix = parent
        
        _matrix.translate(direction: position)
        
        _matrix.rotate(angle: rotation.x, axis: .x_axis)
        _matrix.rotate(angle: rotation.y, axis: .y_axis)
        _matrix.rotate(angle: rotation.z, axis: .z_axis)
        
        _matrix.scale(axis: scale)
    }
}
