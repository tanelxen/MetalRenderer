//
//  Camera.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import simd

class Camera: Node
{
    var projectionMatrix: matrix_float4x4 {
        matrix_identity_float4x4
    }
    
    var viewMatrix: matrix_float4x4 {
        var matrix = matrix_identity_float4x4
        
        matrix.rotate(angle: transform.rotation.x, axis: .x_axis)
        matrix.rotate(angle: transform.rotation.y, axis: .y_axis)
        matrix.rotate(angle: transform.rotation.z, axis: .z_axis)
        
        matrix.translate(direction: -transform.position)
        
        return matrix
    }
}

class DebugCamera: Camera
{
    override var projectionMatrix: matrix_float4x4 {
        matrix_float4x4.perspective(degreesFov: 45, aspectRatio: Renderer.aspectRatio, near: 0.1, far: 1000)
    }
    
    var movementSpeed: Float = 3.0
    var rotateSpeed: Float = 20
    
    var pitch: Float = 0
    var yaw: Float = -90
    
    private var up = float3(0, 1, 0)
    
    private var direction: float3 {
        
        let x = cos(pitch.radians) * cos(yaw.radians)
        let y = sin(pitch.radians)
        let z = cos(pitch.radians) * sin(yaw.radians)

        let dir = float3(x, y, z)

        return normalize(dir)
    }
    
    override var viewMatrix: matrix_float4x4 {
        return getViewMatrix()
    }
    
    func update(deltaTime: Float)
    {
        let forward = direction
        let right = simd_cross(direction, up)
        
        if Keyboard.isKeyPressed(.upArrow) || Keyboard.isKeyPressed(.w)
        {
            transform.position += forward * (movementSpeed * deltaTime)
        }
        
        if Keyboard.isKeyPressed(.downArrow) || Keyboard.isKeyPressed(.s)
        {
            transform.position -= forward * (movementSpeed * deltaTime)
        }
        
        if Keyboard.isKeyPressed(.leftArrow) || Keyboard.isKeyPressed(.a)
        {
            transform.position -= right * (movementSpeed * deltaTime)
        }

        if Keyboard.isKeyPressed(.rightArrow) || Keyboard.isKeyPressed(.d)
        {
            transform.position += right * (movementSpeed * deltaTime)
        }
        
//        if Mouse.IsMouseButtonPressed(.right)
//        {
//            transform.rotation.y += Mouse.getDX() * rotateSpeed * deltaTime
//            transform.rotation.x += Mouse.getDY() * rotateSpeed * deltaTime
//        }
        
        if Mouse.IsMouseButtonPressed(.right)
        {
            pitch -= Mouse.getDY() * rotateSpeed * deltaTime
            yaw += Mouse.getDX() * rotateSpeed * deltaTime
            
            if pitch > 89.0 {
                pitch = 89.0
            }
            
            if pitch < -89.0 {
                pitch = -89.0
            }
        }
    }
    
    private func getViewMatrix() -> matrix_float4x4
    {
//        return lookAt(eye: transform.position, target: transform.position + direction, up: up)
        return lookAt(eye: transform.position, direction: direction, up: up)
    }
}

/**
 Классический lookAt, как в GLM и GLU
 */
func lookAt(eye: float3, target: float3, up: float3) -> matrix_float4x4
{
    let n: float3 = normalize(eye - target)
    let u: float3 = normalize(simd_cross(up, n))
    let v: float3 = simd_cross(n, u)
    
    return matrix_float4x4(
        float4(u.x, v.x, n.x, 0.0),
        float4(u.y, v.y, n.y, 0.0),
        float4(u.z, v.z, n.z, 0.0),
        float4(simd_dot(-u, eye), simd_dot(-v, eye), simd_dot(-n, eye), 1.0)
    )
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
