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
    var rotateSpeed: Float = 0.5
    
    func update(deltaTime: Float)
    {
        if Keyboard.isKeyPressed(.leftArrow) || Keyboard.isKeyPressed(.a)
        {
            transform.position.x -= movementSpeed * deltaTime
        }
        
        if Keyboard.isKeyPressed(.rightArrow) || Keyboard.isKeyPressed(.d)
        {
            transform.position.x += movementSpeed * deltaTime
        }
        
        if Keyboard.isKeyPressed(.upArrow) || Keyboard.isKeyPressed(.w)
        {
            transform.position.z -= movementSpeed * deltaTime
        }
        
        if Keyboard.isKeyPressed(.downArrow) || Keyboard.isKeyPressed(.s)
        {
            transform.position.z += movementSpeed * deltaTime
        }
        
        if Mouse.IsMouseButtonPressed(.right)
        {
            transform.rotation.y += Mouse.getDX() * rotateSpeed * deltaTime
            transform.rotation.x += Mouse.getDY() * rotateSpeed * deltaTime
        }
    }
}
