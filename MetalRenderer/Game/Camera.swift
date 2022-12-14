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
}

class PlayerCamera: Camera
{
    override var projectionMatrix: matrix_float4x4 {
        _projectionMatrix
    }
    
//    override var viewMatrix: matrix_float4x4 {
//        return getViewMatrix()
//    }
    
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
}
