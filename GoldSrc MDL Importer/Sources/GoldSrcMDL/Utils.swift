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

func anglesToQuaternion(_ angles: float3) -> simd_quatf
{
    let pitch = angles[0]
    let roll = angles[1]
    let yaw = angles[2]

    // FIXME: rescale the inputs to 1/2 angle
    let cy = cos(yaw * 0.5)
    let sy = sin(yaw * 0.5)
    let cp = cos(roll * 0.5)
    let sp = sin(roll * 0.5)
    let cr = cos(pitch * 0.5)
    let sr = sin(pitch * 0.5)
    
    let vector = simd_float4(
        sr * cp * cy - cr * sp * sy,    // X
        cr * sp * cy + sr * cp * sy,    // Y
        cr * cp * sy - sr * sp * cy,    // Z
        cr * cp * cy + sr * sp * sy     // W
    )
    
    return simd_quatf(vector: vector)
}

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

func charsToString(_ chars: Chars64) -> String
{
    var bytes = chars
    
    return withUnsafePointer(to: &bytes) { ptr -> String in
       return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
    }
}

func charsToString(_ chars: (CChar, CChar, CChar, CChar)) -> String
{
    var bytes = chars
    
    return withUnsafePointer(to: &bytes) { ptr -> String in
       return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
    }
}

func decode<T>(data: NSData) -> T
{
    let pointer = UnsafeMutablePointer<T>.allocate(capacity: MemoryLayout.size(ofValue:T.self))
    data.getBytes(pointer, length: MemoryLayout<T>.size)
    
    return pointer.move()
}

class AnimValues
{
    func parse(data: Data, seqs: [mstudioseqdesc_t], anims: [[mstudioanim_t]], numBones: Int)
    {
        let AXLES_NUM = 3
        let MAX_SRCBONES = 4
        let animStructLength = MemoryLayout<mstudioanim_t>.size
        
        let reader = BinaryReader(data: data)
        
        sequences = Array(
            repeating: Array(
                repeating: Array(
                    repeating: Array(
                        repeating: animvalue_t(),
                        count: MAX_SRCBONES
                    ),
                    count: AXLES_NUM
                ),
                count: numBones
            ),
            count: seqs.count
        )
        
        for i in 0 ..< seqs.count
        {
            for j in 0 ..< numBones
            {
                let animationIndex = Int(seqs[i].animindex) + j * animStructLength
                
                for axis in 0 ..< AXLES_NUM
                {
                    for v in 0 ..< MAX_SRCBONES
                    {
                        let anim = [anims[i][j].offset.0, anims[i][j].offset.1, anims[i][j].offset.2,
                                    anims[i][j].offset.3, anims[i][j].offset.4, anims[i][j].offset.5]
                        
                        let offset = animationIndex + Int(anim[axis + AXLES_NUM]) + v * MemoryLayout<Int16>.size
                        
                        reader.position = offset
                        let value = reader.getInt16()
                        
                        reader.position = offset
                        let valid = reader.getUInt8()
                        
                        reader.position = offset + MemoryLayout<UInt8>.size
                        let total = reader.getUInt8()
                        
                        sequences[i][j][axis][v].value = Int(value)
                        sequences[i][j][axis][v].valid = Int(valid)
                        sequences[i][j][axis][v].total = Int(total)
                    }
                }
            }
        }
    }
    
    func get(_ sequenceIndex: Int, _ boneIndex: Int, _ axis: Int, _ index: Int, _ anim: ANIM_VALUE) -> Int
    {
        let animvalue = sequences[sequenceIndex][boneIndex][axis][index]
        
        switch anim
        {
            case .TOTAL: return animvalue.total
            case .VALID: return animvalue.valid
            case .VALUE: return animvalue.value
        }
    }
    
    private var sequences: [ [ [ [animvalue_t] ] ] ] = []
    
    enum ANIM_VALUE
    {
        case TOTAL
        case VALID
        case VALUE
    }
    
    struct animvalue_t
    {
        var valid: Int = 0
        var total: Int = 0
        var value: Int = 0
    }
}
