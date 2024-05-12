//
//  Rotator.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 14.12.2022.
//

import simd

struct Rotator
{
    var pitch: Float
    var yaw: Float
    var roll: Float
    
    static let zero = Rotator(pitch: 0, yaw: 0, roll: 0)
    
    var orientation: simd_quatf {

        let qx = simd_quatf(angle: -pitch.radians, axis: [1, 0, 0])
        let qy = simd_quatf(angle: yaw.radians, axis: [0, 1, 0])
        let qz = simd_quatf(angle: roll.radians, axis: [0, 0, 1])
        
        return qz * qy * qx
    }
    
    var forward: float3 {
        orientation.act([0, 0, 1])
    }
    
    var right: float3 {
        orientation.act([1, 0, 0])
    }
    
    var up: float3 {
        orientation.act([0, 1, 0])
    }
    
    var matrix: matrix_float4x4 {
        float4x4(orientation)
    }
}
