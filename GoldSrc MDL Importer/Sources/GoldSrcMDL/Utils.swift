//
//  Utils.swift
//  Half-Life MDL
//
//  Created by Fedor Artemenkov on 15.02.2022.
//

import Foundation
import simd

struct vec3
{
    let x, y, z: Float32
}

typealias float2 = SIMD2<Float>
typealias float3 = SIMD3<Float>

extension simd_float3
{
    /// Более корректно, но медленно
    static func * (lhs: simd_float4x4, rhs: simd_float3) -> simd_float3
    {
        let result = lhs * simd_float4(rhs.x, rhs.y, rhs.z, 1)
        return simd_float3(result.x/result.w, result.y/result.w, result.z/result.w)
    }
}

//func anglesToQuaternion(_ angles: float3) -> simd_quatf
//{
//    let pitch = angles[0]
//    let roll = angles[1]
//    let yaw = angles[2]
//
//    // FIXME: rescale the inputs to 1/2 angle
//    let cy = cos(yaw * 0.5)
//    let sy = sin(yaw * 0.5)
//    let cp = cos(roll * 0.5)
//    let sp = sin(roll * 0.5)
//    let cr = cos(pitch * 0.5)
//    let sr = sin(pitch * 0.5)
//    
//    let vector = simd_float4(
//        sr * cp * cy - cr * sp * sy,    // X
//        cr * sp * cy + sr * cp * sy,    // Y
//        cr * cp * sy - sr * sp * cy,    // Z
//        cr * cp * cy + sr * sp * sy     // W
//    )
//    
//    return simd_quatf(vector: vector)
//}

typealias Chars32 = (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                     CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                     CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                     CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar)

typealias Chars64 = (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                     CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                     CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                     CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                     CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                     CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                     CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                     CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar)

func charsToString<T>(_ chars: T) -> String
{
    var bytes = chars
    
    return withUnsafeBytes(of: &bytes) { rawPtr in
        let ptr = rawPtr.baseAddress!.assumingMemoryBound(to: CChar.self)
        return String(cString: ptr)
    }
}
