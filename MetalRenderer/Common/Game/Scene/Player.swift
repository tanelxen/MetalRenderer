//
//  Player.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 19.02.2022.
//

import simd
import Foundation

class Player
{
    var transform = Transform()
    var mesh: SkeletalMesh?
    
    let camera = PlayerCamera()
    
    private var rotateSpeed: Float = 30.0
    
    private var velocity: float3 = .zero
    
    private weak var scene: Q3MapScene!
    
    private var playerMovement = PlayerMovement()
    
    private let footsteps = ["pl_step1.wav",
                             "pl_step2.wav",
                             "pl_step3.wav",
                             "pl_step4.wav"]
    
    private let shootTimer: TimerManager
    
    private var bobing: Float = 0.0
    
    init(scene: Q3MapScene)
    {
        self.scene = scene
        
        if let url = ResourceManager.getURL(for: "Assets/models/v_9mmhandgun/mesh.skl")
        {
            self.mesh = SkeletalMesh(url: url)
        }
        
        playerMovement.scene = scene
        
        let shootRate = TimeInterval(mesh?.cur_anim_duration ?? 10)
        shootTimer = TimerManager(interval: shootRate)
        
        mesh?.sequenceName = "idle3"
        
        setupEvents()
    }
    
    private func setupEvents()
    {
        playerMovement.playStepsSound = { [weak self] in
            if let footstep = self?.footsteps.randomElement() {
                AudioEngine.play(file: footstep)
            }
        }
        
        Mouse.onLeftMouseDown = { [weak self] in
            self?.shootTimer.start { [weak self] in
                self?.makeShoot()
            }
        }

        Mouse.onLeftMouseUp = { [weak self] in
            self?.shootTimer.stop()
        }
    }
    
    func update()
    {
        playerMovement.transform = transform
        
        updateInput()
        updateMovement()
        
        bobing = playerMovement.isWalking ? bobing + GameTime.deltaTime : 0
        let bob = sin(bobing * 16) * 1.2
        
        camera.transform.position = transform.position + float3(0, 0, 40 + bob)
        camera.transform.rotation = transform.rotation
    }
    
    private func makeShoot()
    {
        AudioEngine.play(file: "pl_gun3.wav")
        
        mesh?.sequenceName = "shoot"
        let duration = Double(mesh?.cur_anim_duration ?? 0)

        Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { timer in
            self.mesh?.sequenceName = "idle3"
        }
        
        let start = camera.transform.position
        let end = start + camera.transform.rotation.forward * 1024
        
        scene.makeShoot(start: start, end: end)
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
        
        transform.rotation.yaw -= Mouse.getDX() * rotateSpeed * deltaTime
        transform.rotation.pitch += Mouse.getDY() * rotateSpeed * deltaTime
    }
}

class TimerManager
{
    private var timer: Timer?
    private var lastEventTime = Date.distantFuture
    private var interval: TimeInterval
    
    init(interval: TimeInterval) {
        self.interval = interval
    }
    
    func start(action: @escaping () -> Void)
    {
        let now = Date()
        if abs(lastEventTime.timeIntervalSince(now)) < interval
        {
            // Время ещё не вышло, ждём следующего запуска таймера
            return
        }
        
        // Создаем новое событие
        action()
        lastEventTime = now
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.start(action: action)
        }
    }
    
    func stop()
    {
        timer?.invalidate()
        timer = nil
    }
}
