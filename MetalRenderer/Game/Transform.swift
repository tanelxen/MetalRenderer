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
    
    var matrix: matrix_float4x4 {
        var matrix = parent
        
        matrix.translate(direction: position)
        
        matrix.rotate(angle: rotation.x, axis: .x_axis)
        matrix.rotate(angle: rotation.y, axis: .y_axis)
        matrix.rotate(angle: rotation.z, axis: .z_axis)
        
        matrix.scale(axis: scale)
        
        return matrix
    }
}
