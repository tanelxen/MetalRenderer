//
//  Math.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import simd

extension Float
{
    var radians: Float {
        return self * Float.pi / 180.0
    }
    
    var degrees: Float {
        return self * 180.0 / Float.pi
    }
    
    static var randomNormalized: Float {
        Float(arc4random()) / Float(UINT32_MAX)
    }
}

extension float3
{
    static let x_axis = float3(1, 0, 0)
    static let y_axis = float3(0, 1, 0)
    static let z_axis = float3(0, 0, 1)
}

extension float4
{
    static var randomColor: float4 {
        float4(.randomNormalized, .randomNormalized, .randomNormalized, 1.0)
    }
}

extension simd_float3
{
    /// Более корректно, но медленно
    public static func * (lhs: simd_float4x4, rhs: simd_float3) -> simd_float3
    {
        let result = lhs * simd_float4(rhs.x, rhs.y, rhs.z, 1)
        return simd_float3(result.x/result.w, result.y/result.w, result.z/result.w)
    }
    
//    static func * (lhs: simd_float4x4, rhs: simd_float3) -> simd_float3
//    {
//        let result = lhs * simd_float4(rhs.x, rhs.y, rhs.z, 1)
//        return simd_float3(result.x, result.y, result.z)
//    }
    
    func translate(_ matrix: inout simd_float4x4) -> simd_float3
    {
        let result = matrix * simd_float4(x, y, z, 1)
        return simd_float3(result.x, result.y, result.z)
    }
}

extension matrix_float4x4
{
    mutating func translate(direction: float3)
    {
        var result = matrix_identity_float4x4
        
        let x = direction.x
        let y = direction.y
        let z = direction.z
        
        result.columns = (
            float4(1, 0, 0, 0),
            float4(0, 1, 0, 0),
            float4(0, 0, 1, 0),
            float4(x, y, z, 1)
        )
        
        self = matrix_multiply(self, result)
    }
    
    mutating func scale(axis: float3)
    {
        var result = matrix_identity_float4x4
        
        let x = axis.x
        let y = axis.y
        let z = axis.z
        
        result.columns = (
            float4(x, 0, 0, 0),
            float4(0, y, 0, 0),
            float4(0, 0, z, 0),
            float4(0, 0, 0, 1)
        )
        
        self = matrix_multiply(self, result)
    }
    
    mutating func rotate(angle: Float, axis: float3)
    {
        var result = matrix_identity_float4x4
        
        let x: Float = axis.x
        let y: Float = axis.y
        let z: Float = axis.z
        
        let c: Float = cos(angle)
        let s: Float = sin(angle)
        
        let mc: Float = (1 - c)
        
        let r1c1: Float = x * x * mc + c
        let r2c1: Float = x * y * mc + z * s
        let r3c1: Float = x * z * mc - y * s
        let r4c1: Float = 0.0
        
        let r1c2: Float = y * x * mc - z * s
        let r2c2: Float = y * y * mc + c
        let r3c2: Float = y * z * mc + x * s
        let r4c2: Float = 0.0
        
        let r1c3: Float = z * x * mc + y * s
        let r2c3: Float = z * y * mc - x * s
        let r3c3: Float = z * z * mc + c
        let r4c3: Float = 0.0
        
        let r1c4: Float = 0.0
        let r2c4: Float = 0.0
        let r3c4: Float = 0.0
        let r4c4: Float = 1.0
        
        result.columns = (
            float4(r1c1, r2c1, r3c1, r4c1),
            float4(r1c2, r2c2, r3c2, r4c2),
            float4(r1c3, r2c3, r3c3, r4c3),
            float4(r1c4, r2c4, r3c4, r4c4)
        )
        
        self = matrix_multiply(self, result)
    }
    
    static func perspective(degreesFov: Float, aspectRatio: Float, near: Float, far: Float) -> matrix_float4x4
    {
        let fov = degreesFov.radians
        
        let t: Float = tan(fov / 2)
        
        let x: Float = 1 / (aspectRatio * t)
        let y: Float = 1 / t
        let z: Float = -((far + near) / (far - near))
        let w: Float = -((2 * far * near) / (far - near))
        
        var result = matrix_identity_float4x4
        
        result.columns = (
            float4(x,  0,  0,   0),
            float4(0,  y,  0,   0),
            float4(0,  0,  z,  -1),
            float4(0,  0,  w,   0)
        )
        
        return result
    }
    
    static func orthographic(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float)->matrix_float4x4{
        return float4x4 (
            [ 2 / (right - left), 0, 0, 0 ],
            [ 0, 2 / (top - bottom), 0, 0 ],
            [ 0, 0, -2 / (far - near), 0 ],
            [ 0,0,0,1 ]
        )
     }
    
    static func orthographic(width: Float, height: Float, length: Float)->matrix_float4x4{
        return float4x4 (
            [ Float(2.0) / width,   0,                      0,                      0 ],
            [ 0,                    Float(2.0) / height,    0,                      0 ],
            [ 0,                    0,                      -Float(2.0) / length,    0 ],
            [ 0,                    0,                      0,                      Float(1.0) ]
        )
     }
}

//struct AABB
//{
//    var min: float3
//    var max: float3
//}

struct Plane
{
    var normal: float3
    var distance: Float
}

func testAABBPlane(min: float3, max: float3, plane: Plane) -> Bool
{
    let c: float3 = (min + max) * 0.5
    let e: float3 = max - c
    let r: Float = e.x * abs(plane.normal.x) + e.y * abs(plane.normal.y) + e.x * abs(plane.normal.z)
    let s: Float = simd_dot(plane.normal, c) - plane.distance
    
    return abs(s) <= r
}

/**
 Classic lookAt, likewise in GLM
 */
func lookAt(eye: float3, target: float3, up: float3) -> matrix_float4x4
{
    let n: float3 = normalize(eye - target)
    let u: float3 = normalize(simd_cross(up, n))
    let v: float3 = simd_cross(n, u)
    
    return matrix_float4x4(rows: [
        float4(u.x, u.y, u.z, dot(-u, eye)),
        float4(v.x, v.y, v.z, dot(-v, eye)),
        float4(n.x, n.y, n.z, dot(-n, eye)),
        float4(0.0, 0.0, 0.0, 1.0)
    ])
}

func lookAt(eye: float3, direction: float3, up: float3) -> matrix_float4x4
{
    let n: float3 = -direction
    let u: float3 = normalize(simd_cross(up, n))
    let v: float3 = simd_cross(n, u)
    
    return matrix_float4x4(
        float4(u.x, v.x, n.x, 0.0),
        float4(u.y, v.y, n.y, 0.0),
        float4(u.z, v.z, n.z, 0.0),
        float4(simd_dot(-u, eye), simd_dot(-v, eye), simd_dot(-n, eye), 1.0)
    )
}
