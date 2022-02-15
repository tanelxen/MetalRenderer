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
    
    var eyeHeight: Float = 0.2
    
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
        _projectionMatrix
    }
    
    private var _projectionMatrix: matrix_float4x4 = matrix_identity_float4x4
    
    static var shared = DebugCamera()
    
    var movementSpeed: Float = 300.0
    var rotateSpeed: Float = 20
    
    var pitch: Float = 0
    var yaw: Float = 90
    
//    var desiredPosition: float3 = .zero
    
    var velocity: float3 = .zero
    
    private var up = float3(0, 1, 0)
    
    private var direction: float3 {
        
        let x = cos(pitch.radians) * cos(yaw.radians)
        let y = sin(pitch.radians)
        let z = cos(pitch.radians) * sin(yaw.radians)

        let dir = float3(x, y, z)

        return normalize(dir)
    }
    
    private var frustumPlanes: [Plane] = []
    
    override var viewMatrix: matrix_float4x4 {
        return getViewMatrix()
    }
    
    func update(deltaTime: Float)
    {
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
        
//        desiredPosition = transform.position + velocity
        
//        transform.position.y = eyeHeight
        
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
        
        _projectionMatrix = matrix_float4x4.perspective(degreesFov: 65, aspectRatio: ForwardRenderer.aspectRatio, near: 0.1, far: 5000)
        
        frustumPlanes = DebugCamera.frustumPlanes(from: (_projectionMatrix * viewMatrix).transpose)
    }
    
    private func getViewMatrix() -> matrix_float4x4
    {
//        return lookAt(eye: transform.position, target: transform.position + direction, up: up)
        return lookAt(eye: transform.position, direction: direction, up: up)
    }
    
    func pointInFrustum(_ point: float3) -> Bool
    {
        for plane in frustumPlanes
        {
            let distance = plane.normal.x * point.x + plane.normal.y * point.y + plane.normal.z * point.z + plane.distance
            
            if distance <= 0 { return false }
        }

       return true
    }
    
    func sphereInFrustum(_ point: float3, radius: Float) -> Bool
    {
        for plane in frustumPlanes
        {
            let distance = plane.normal.x * point.x + plane.normal.y * point.y + plane.normal.z * point.z + plane.distance
            
            if distance <= -radius { return false }
        }

       return true
    }
    
    func boxInFrustum(mins: float3, maxs: float3) -> Bool
    {
        // check box outside/inside of frustum
        for plane in frustumPlanes
        {
            var out: Int = 0
            
            out += simd_dot(plane.normal, float3(mins.x, mins.y, mins.z)) + plane.distance < 0 ? 1 : 0
            out += simd_dot(plane.normal, float3(maxs.x, mins.y, mins.z)) + plane.distance < 0 ? 1 : 0
            out += simd_dot(plane.normal, float3(mins.x, maxs.y, mins.z)) + plane.distance < 0 ? 1 : 0
            out += simd_dot(plane.normal, float3(maxs.x, maxs.y, mins.z)) + plane.distance < 0 ? 1 : 0
            
            out += simd_dot(plane.normal, float3(mins.x, mins.y, maxs.z)) + plane.distance < 0 ? 1 : 0
            out += simd_dot(plane.normal, float3(maxs.x, mins.y, maxs.z)) + plane.distance < 0 ? 1 : 0
            out += simd_dot(plane.normal, float3(mins.x, maxs.y, maxs.z)) + plane.distance < 0 ? 1 : 0
            out += simd_dot(plane.normal, float3(maxs.x, maxs.y, maxs.z)) + plane.distance < 0 ? 1 : 0
            
            if out == 8 { return false }
        }

        return true
    }
    
    func aabbInFrustum(min: float3, max: float3) -> Bool
    {
        // check box outside/inside of frustum
        for plane in frustumPlanes
        {
            var out: Int = 0
            
            out += testAABBPlane(min: min, max: max, plane: plane) ? 1 : 0

            if out == 8 { return true }
        }

        return false
    }
    
    func meshInFrustum(vertices: [float3]) -> Bool
    {
        for vertex in vertices
        {
            if pointInFrustum(vertex)
            {
                return true
            }
        }
        
        return false
    }
    
    static func frustumPlanes(from mat: matrix_float4x4) -> [Plane]
    {
        let p: [Plane] = [
            normalizePlane(
                mat[3][0] + mat[0][0],
                mat[3][1] + mat[0][1],
                mat[3][2] + mat[0][2],
                mat[3][3] + mat[0][3]), // left
            
            normalizePlane(
                mat[3][0] - mat[0][0],
                mat[3][1] - mat[0][1],
                mat[3][2] - mat[0][2],
                mat[3][3] - mat[0][3]), // right
            
            normalizePlane(
                mat[3][0] - mat[1][0],
                mat[3][1] - mat[1][1],
                mat[3][2] - mat[1][2],
                mat[3][3] - mat[1][3]), // top
            
            normalizePlane(
                mat[3][0] + mat[1][0],
                mat[3][1] + mat[1][1],
                mat[3][2] + mat[1][2],
                mat[3][3] + mat[1][3]), // bottom
            
            normalizePlane(
                mat[3][0] + mat[2][0],
                mat[3][1] + mat[2][1],
                mat[3][2] + mat[2][2],
                mat[3][3] + mat[2][3]), // near
            
            normalizePlane(
                mat[3][0] - mat[2][0],
                mat[3][1] - mat[2][1],
                mat[3][2] - mat[2][2],
                mat[3][3] - mat[2][3])  // far
        ]
        
        return p
    }
    
    static func normalizePlane(_ A: Float, _ B: Float, _ C: Float, _ D: Float) -> Plane
    {
        let nf: Float = 1.0 / sqrt(A * A + B * B + C * C)

        return Plane(normal: float3(nf * A, nf * B, nf * C), distance: nf * D)
    }
}

struct Plane
{
    var normal: float3
    var distance: Float
}

/**
 Classic lookAt, likewise in GLM
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
