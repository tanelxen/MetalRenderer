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
    
    var viewportBoundsMin: SIMD2<Float> = [0, 0]
    var viewportBoundsMax: SIMD2<Float> = [1, 1]
    
    var projectionMatrix: matrix_float4x4 {
        matrix_identity_float4x4
    }
    
    var viewMatrix: matrix_float4x4 {
        let R = transform.rotation.matrix
        let T = float4x4(translation: transform.position)
        return simd_mul(T, R).inverse
    }
    
    func update() { }
    
    func mousePositionInWorld() -> Ray
    {
        let positionX = viewportBoundsMin.x
        let positionY = viewportBoundsMin.y
        let sizeX = viewportBoundsMax.x - viewportBoundsMin.x
        let sizeY = viewportBoundsMax.y - viewportBoundsMin.y
        
        let mousePos = Mouse.getMouseWindowPosition()
        
        let ndcX = ((mousePos.x - positionX) / sizeX) * 2 - 1
        let ndcY = (1 - ((mousePos.y - positionY) / sizeY)) * 2 - 1
        
        let clipCoords = float4(ndcX, ndcY, 0, 1)
        
        let projInv = projectionMatrix.inverse
        let viewInv = viewMatrix.inverse
        
        var eyeRayDir = projInv * clipCoords
        eyeRayDir.z = -1
        eyeRayDir.w = 0
        
        var worldRayDir = (viewInv * eyeRayDir).xyz
        worldRayDir = normalize(worldRayDir)
        
        let eyeRayOrigin = float4(x: 0, y: 0, z: 0, w: 1)
        let worldRayOrigin = (viewInv * eyeRayOrigin).xyz
        
        return Ray(origin: worldRayOrigin, direction: worldRayDir)
    }
    
    func updateViewport(width: Int, height: Int) { }
}

struct Ray
{
    var origin: float3
    var direction: float3
}

class PlayerCamera: Camera
{
    override var projectionMatrix: matrix_float4x4 {
        _projectionMatrix
    }
    
    private var _projectionMatrix: matrix_float4x4 = matrix_identity_float4x4
    
    override init()
    {
        super.init()
        _projectionMatrix = matrix_float4x4.perspective(degreesFov: 65, aspectRatio: 1.0, near: 0.1, far: 5000)
    }
    
    override func updateViewport(width: Int, height: Int)
    {
        guard width > 0, height > 0 else { return }

        let aspectRatio = Float(width) / Float(height)
        
        _projectionMatrix = matrix_float4x4.perspective(degreesFov: 65, aspectRatio: aspectRatio, near: 0.01, far: 5000)
    }
}

class DebugCamera: Camera
{
    override var projectionMatrix: matrix_float4x4 {
        _projectionMatrix
    }
    
    private var _projectionMatrix: matrix_float4x4 = matrix_identity_float4x4
    
    private let movementSpeed: Float = 400
    private let rotateSpeed: Float = 20
    
    private var velocity: float3 = .zero
    
    override func update()
    {
        guard Mouse.IsMouseButtonPressed(.right) else { return }
        
        let deltaTime = GameTime.deltaTime
        
        transform.rotation.yaw += Mouse.getDX() * rotateSpeed * deltaTime
        transform.rotation.pitch -= Mouse.getDY() * rotateSpeed * deltaTime
        
        let forward = transform.rotation.forward
        let right = transform.rotation.right
        
        velocity = .zero
        
        if Keyboard.isKeyPressed(.w)
        {
            velocity += forward * (movementSpeed * deltaTime)
        }

        if Keyboard.isKeyPressed(.s)
        {
            velocity -= forward * (movementSpeed * deltaTime)
        }

        if Keyboard.isKeyPressed(.a)
        {
            velocity -= right * (movementSpeed * deltaTime)
        }

        if Keyboard.isKeyPressed(.d)
        {
            velocity += right * (movementSpeed * deltaTime)
        }
        
        transform.position += velocity
    }
    
    override func updateViewport(width: Int, height: Int)
    {
        guard width > 0, height > 0 else { return }

        let aspectRatio = Float(width) / Float(height)
        
        _projectionMatrix = matrix_float4x4.perspective(degreesFov: 65, aspectRatio: aspectRatio, near: 0.1, far: 5000)
    }
}

class OrthoCamera: Camera
{
    override var projectionMatrix: matrix_float4x4 {
        _projectionMatrix
    }
    
    private var _projectionMatrix: matrix_float4x4 = matrix_identity_float4x4
    
    private let movementSpeed: Float = 32
    private let zoomSpeed: Float = 2
    
    private var width: Float = 1
    private var height: Float = 1
    private var zoom: Float = 8
    
    override func update()
    {
        let deltaTime = GameTime.deltaTime
        
        zoom -= Mouse.getDeltaWheel() * zoomSpeed * deltaTime
        
        if zoom < 0.5 {
            zoom = 0.5
        }
        
        if zoom > 32 {
            zoom = 32
        }
        
        if Mouse.IsMouseButtonPressed(.right)
        {
            transform.position.x -= Mouse.getDX() * movementSpeed * deltaTime
            transform.position.z += Mouse.getDY() * movementSpeed * deltaTime
        }
        
        updateProjectionMatrix()
    }
    
    override func updateViewport(width: Int, height: Int)
    {
        guard width > 0, height > 0 else { return }

        self.width = Float(width)
        self.height = Float(height)
        
        updateProjectionMatrix()
    }
    
    private func updateProjectionMatrix()
    {
        let w = width / zoom
        let h = height / zoom
        
        _projectionMatrix = matrix_float4x4.orthographic(left: -w,
                                                         right: w,
                                                         bottom: -h,
                                                         top: h,
                                                         near: 0.1,
                                                         far: 1024)
    }
}
