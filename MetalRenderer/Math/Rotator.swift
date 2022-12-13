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
    
    var forward: float3 {
        
        let cp = cos(pitch.radians)
        let sp = sin(pitch.radians)

        let cy = cos(yaw.radians)
        let sy = sin(yaw.radians)

//        let dir = float3(cp * cy, cp * sy, -sp)
        let dir = float3(cp * cy, -sp, -cp * sy)

        return normalize(dir)
    }
    
    var right: float3 {
        
        let cp = cos(pitch.radians)
        let sp = sin(pitch.radians)

        let cy = cos(yaw.radians)
        let sy = sin(yaw.radians)

        let cr = cos(roll.radians)
        let sr = sin(roll.radians)

//        let dir = float3(
//            -1 * sr * sp * cy - 1 * cr * -sy,
//            -1 * sr * sp * sy - 1 * cr * cy,
//            -1 * sr * cp
//        )
        
        let dir = float3(
            -1 * sr * sp * cy + cr * sy,
            -1 * sr * cp,
            sr * sp * sy + cr * cy
        )

        return normalize(dir)
    }
    
    var up: float3 {
        
        let cp = cos(pitch.radians)
        let sp = sin(pitch.radians)

        let cy = cos(yaw.radians)
        let sy = sin(yaw.radians)

        let cr = cos(roll.radians)
        let sr = sin(roll.radians)

//        let dir = float3(
//            cr * sp * cy - sr * -sy,
//            cr * sp * sy - sr * cy,
//            cr * cp
//        )
        
        let dir = float3(
            cr * sp * cy + sr * sy,
            cr * cp,
            -cr * sp * sy + sr * cy
        )

        return normalize(dir)
    }
    
    var matrix: matrix_float4x4 {
        
        let cp = cos(pitch.radians)
        let sp = sin(pitch.radians)

        let cy = cos(yaw.radians)
        let sy = sin(yaw.radians)

        let cr = cos(roll.radians)
        let sr = sin(roll.radians)
        
        var m: matrix_float4x4 = matrix_identity_float4x4
        
        m[0][0] = cy * cr + sy * sp * sr
        m[1][0] = cr * sy * sp - sr * cy
        m[2][0] = cp * sy
        
        m[0][1] = cp * sr
        m[1][1] = cr * cp
        m[2][1] = -sp
        
        m[0][2] = sr * cy * sp - sy * cr
        m[1][2] = sy * sr + cr * cy * sp
        m[2][2] = cp * cy
        
        return m
    }
}
