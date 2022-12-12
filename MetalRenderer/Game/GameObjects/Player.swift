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
    
    private var playerMovement = PlayerMovement()
    
    init(scene: Q3MapScene)
    {
        self.scene = scene
        
        CameraManager.shared.mainCamera = camera
        
        playerMovement.scene = scene
    }
    
    func posses()
    {
        CameraManager.shared.mainCamera = camera
    }
    
    func update()
    {
        updateInput()
        
        playerMovement.transform = transform
        
        updateMovement()
        
        camera.transform.position = transform.position + float3(0, 64, 0)
        camera.transform.rotation = transform.rotation
    }
    
    private func updateMovement()
    {
        playerMovement.update()
        transform.position = playerMovement.transform.position
        
//        camera.transform.position += camera.velocity
    }
    
    private func updateInput()
    {
        let deltaTime = GameTime.deltaTime

        playerMovement.forwardmove = 0
        playerMovement.rightmove = 0
        
        if Keyboard.isKeyPressed(.w)
        {
            playerMovement.forwardmove = 1
        }

        else if Keyboard.isKeyPressed(.s)
        {
            playerMovement.forwardmove = -1
        }
        
        if Keyboard.isKeyPressed(.a)
        {
            playerMovement.rightmove = -1
        }

        if Keyboard.isKeyPressed(.d)
        {
            playerMovement.rightmove = 1
        }
        
        if Mouse.IsMouseButtonPressed(.right)
        {
            transform.rotation.y += Mouse.getDX() * rotateSpeed * deltaTime
            transform.rotation.x -= Mouse.getDY() * rotateSpeed * deltaTime
        }
    }
}
