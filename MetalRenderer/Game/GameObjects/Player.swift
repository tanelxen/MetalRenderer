//
//  Player.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 19.02.2022.
//

import simd

class Player
{
    var transform = Transform()
    
    let camera = PlayerCamera()
    
    private var movementSpeed: Float = 300.0
    private var rotateSpeed: Float = 20.0
    
    private var velocity: float3 = .zero
    
    private var up = float3(0, 1, 0)
    
    private weak var scene: Q3MapScene?
    
    private var isFreeFly = false
    
    init(scene: Q3MapScene)
    {
        self.scene = scene
        
        CameraManager.shared.mainCamera = camera
    }
    
    func posses()
    {
        CameraManager.shared.mainCamera = camera
    }
    
    func update()
    {
        updateInput()
        updateMovement()
        
        camera.transform.position = transform.position + float3(0, 64, 0)
        camera.transform.rotation = transform.rotation
    }
    
    private func updateMovement()
    {
        transform.position += velocity
        
//        camera.transform.position += camera.velocity
    }
    
    private func updateInput()
    {
        let deltaTime = GameTime.deltaTime
        
        let up = float3(0, 1, 0)
        var forward = transform.forward
        
        if !isFreeFly
        {
            forward *= float3(1, 0, 1)
        }
        
        let right = simd_cross(forward, up)
        
        velocity = .zero
        
        if Keyboard.isKeyPressed(.w)
        {
            velocity = forward * (movementSpeed * deltaTime)
        }

        else if Keyboard.isKeyPressed(.s)
        {
            velocity = -forward * (movementSpeed * deltaTime)
        }
        
        if Keyboard.isKeyPressed(.a)
        {
            velocity = -right * (movementSpeed * deltaTime)
        }

        if Keyboard.isKeyPressed(.d)
        {
            velocity = right * (movementSpeed * deltaTime)
        }
        
        if Mouse.IsMouseButtonPressed(.right)
        {
            transform.rotation.y += Mouse.getDX() * rotateSpeed * deltaTime
            
            transform.rotation.x -= Mouse.getDY() * rotateSpeed * deltaTime
//            transform.rotation.y = max(-89, min(89, transform.rotation.y))
        }
    }
}
