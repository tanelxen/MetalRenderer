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
    var mesh: SkeletalMesh?
    
    let camera = PlayerCamera()
    
    private var rotateSpeed: Float = 30.0
    
    private var velocity: float3 = .zero
    
    private weak var scene: Q3MapScene?
    
    private var playerMovement = PlayerMovement()
    
    init(scene: Q3MapScene)
    {
        self.scene = scene
        self.mesh = SkeletalMesh(name: "Assets/hl/models/v_9mmhandgun.mdl")
        
        mesh?.sequenceName = "idle3"
        
        CameraManager.shared.mainCamera = camera
        
        playerMovement.scene = scene
    }
    
    func posses()
    {
        CameraManager.shared.mainCamera = camera
    }
    
    func update()
    {
        playerMovement.transform = transform
        
        updateInput()
        updateMovement()
        
        camera.transform.position = transform.position + float3(0, 0, 40)
        camera.transform.rotation = transform.rotation
    }
    
    private func updateMovement()
    {
        playerMovement.update()
        transform.position = playerMovement.transform.position
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

        if Keyboard.isKeyPressed(.s)
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
        
        if Keyboard.isKeyPressed(.leftArrow)
        {
            transform.rotation.yaw += rotateSpeed * deltaTime
        }
        
        if Keyboard.isKeyPressed(.rightArrow)
        {
            transform.rotation.yaw -= rotateSpeed * deltaTime
        }
        
        if Keyboard.isKeyPressed(.upArrow)
        {
            transform.rotation.pitch -= rotateSpeed * deltaTime
        }
        
        if Keyboard.isKeyPressed(.downArrow)
        {
            transform.rotation.pitch += rotateSpeed * deltaTime
        }
        
        playerMovement.isWishJump = Keyboard.isKeyPressed(.space)
        
        if Mouse.IsMouseButtonPressed(.right)
        {
            transform.rotation.yaw -= Mouse.getDX() * rotateSpeed * deltaTime
            transform.rotation.pitch += Mouse.getDY() * rotateSpeed * deltaTime
        }
    }
}
