//
//  Camera.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import simd

class Camera
{
    var transform = Transform()
    
    var projectionMatrix: matrix_float4x4 {
        matrix_identity_float4x4
    }
    
    var viewMatrix: matrix_float4x4 {
        
        /*
         * quake3 uses a different coordinate system, so we use quake's matrix
         * as identity, where x, y, z are forward, left and up
         */
        var matrix = matrix_float4x4([
            float4(0, 0, -1, 0),
            float4(-1, 0, 0, 0),
            float4(0, 1, 0, 0),
            float4(0, 0, 0, 1)
        ])
        
        matrix.rotate(angle: -transform.rotation.pitch.radians, axis: .y_axis)
        matrix.rotate(angle: -transform.rotation.yaw.radians, axis: .z_axis)
        
        matrix.translate(direction: -transform.position)
        
        return matrix
    }
    
    func update() { }
    
    var mousePositionInWorld: float3
    {
        let ndc = Mouse.getMouseViewportPosition()
        let ndc3d = float3(ndc.x, ndc.y, 0)
        
        let projInv = projectionMatrix.inverse
        
        let world = projInv * ndc3d
        
        return float3(world.x, transform.position.y, world.y)
    }
    
    func updateViewport() { }
}

class PlayerCamera: Camera
{
    override var projectionMatrix: matrix_float4x4 {
        _projectionMatrix
    }
    
//    override var viewMatrix: matrix_float4x4 {
//        return getViewMatrix()
//    }
    
    override var mousePositionInWorld: float3
    {
        let ndc = Mouse.getMouseViewportPosition()
        let ndc3d = float3(ndc.x, ndc.y, 0)
        
        let projInv = _projectionMatrix.inverse
        
        let world = transform.matrix * projInv * ndc3d
        
        return float3(world.x, transform.position.y, world.y)
    }
    
    private var _projectionMatrix: matrix_float4x4 = matrix_identity_float4x4
    
    override init()
    {
        super.init()
        _projectionMatrix = matrix_float4x4.perspective(degreesFov: 65, aspectRatio: ForwardRenderer.aspectRatio, near: 0.1, far: 5000)
    }
    
//    private func getViewMatrix() -> matrix_float4x4
//    {
//        let up = float3(0, 0, 1)
//        let target = transform.position + transform.rotation.forward
//        return lookAt(eye: transform.position, target: target, up: up)
//    }
    
    override func updateViewport()
    {
        _projectionMatrix = matrix_float4x4.perspective(degreesFov: 65, aspectRatio: ForwardRenderer.aspectRatio, near: 0.1, far: 5000)
    }
}

class DebugCamera: Camera
{
    override var projectionMatrix: matrix_float4x4 {
        _projectionMatrix
    }
    
    private var _projectionMatrix: matrix_float4x4 = matrix_identity_float4x4
    
    var movementSpeed: Float = 500.0
    var rotateSpeed: Float = 20
    
    var pitch: Float = 0
    var yaw: Float = 90
    
    var velocity: float3 = .zero
    
    private var up = float3(0, 1, 0)
    
    var direction: float3 {
        
        let x = cos(pitch.radians) * cos(yaw.radians)
        let y = sin(pitch.radians)
        let z = cos(pitch.radians) * sin(yaw.radians)

        let dir = float3(x, y, z)

        return normalize(dir)
    }
    
    override var viewMatrix: matrix_float4x4 {
        return getViewMatrix()
    }
    
    override func update()
    {
        let deltaTime = GameTime.deltaTime
        
        let forward = direction
        let right = simd_cross(direction, up)
        
        velocity = .zero
        
        if Keyboard.isKeyPressed(.upArrow) || Keyboard.isKeyPressed(.w)
        {
            velocity = forward * (movementSpeed * deltaTime)
        }
        
        if Keyboard.isKeyPressed(.downArrow) || Keyboard.isKeyPressed(.s)
        {
            velocity = -forward * (movementSpeed * deltaTime)
        }
        
        if Keyboard.isKeyPressed(.leftArrow) || Keyboard.isKeyPressed(.a)
        {
            velocity = -right * (movementSpeed * deltaTime)
        }

        if Keyboard.isKeyPressed(.rightArrow) || Keyboard.isKeyPressed(.d)
        {
            velocity = right * (movementSpeed * deltaTime)
        }
        
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
        
        transform.position += velocity
        
        _projectionMatrix = matrix_float4x4.perspective(degreesFov: 65, aspectRatio: ForwardRenderer.aspectRatio, near: 0.1, far: 5000)
    }
    
    private func getViewMatrix() -> matrix_float4x4
    {
        return lookAt(eye: transform.position, target: transform.position + direction, up: up)
    }
}
