//
//  Player.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 19.02.2022.
//

import simd
import Foundation
import BulletSwift

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
    
    private (set) var motionState: MotionState?
    private (set) var rigidBody: BulletRigidBody?
    
    private let q2b: Float = 2.54 / 100
    private let b2q: Float = 100 / 2.54
    
    private var forwardmove: Float = 0.0
    private var rightmove: Float = 0.0
    private var isWishJump = false
    
    private var isGrounded = false
    
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
    
    func spawn(with transform: Transform)
    {
        self.transform = transform
        setupRigidBody()
    }
    
    private func setupRigidBody()
    {
        let shape = BulletCapsuleShape(radius: 15 * q2b, height: 28 * q2b, up: .z)
        
        let startTransform = BulletTransform()
        startTransform.setIdentity()
        startTransform.origin = transform.position * q2b
        
        let mass: Float = 1.0
        let localInertia = shape.calculateLocalInertia(mass: mass)
        
        let motionState = MotionState(transform: startTransform)
        
        let body = BulletRigidBody(mass: mass,
                                   motionState: motionState,
                                   collisionShape: shape,
                                   localInertia: localInertia)
        
        body.forceActivationState(.disableDeactivation)
        
        self.motionState = motionState
        self.rigidBody = body
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
        updateInput()
//        updateQuakeMovement()
        updateBtMovement()
        
        camera.transform.position = transform.position + float3(0, 0, 40)
        camera.transform.rotation = transform.rotation
    }
    
    private func updateQuakeMovement()
    {
        playerMovement.transform = transform
        playerMovement.update()
        
        transform.position = playerMovement.transform.position
    }
    
    // Movement based on Bullet's rigid body
    private func updateBtMovement()
    {
        traceGround()
        
        var forward = transform.rotation.forward
        var right = transform.rotation.right
        
        forward.z = 0
        right.z = 0
        
        var direction: float3 = .zero
        direction += forward * forwardmove * 200 * q2b
        direction += right * rightmove * 150 * q2b
        
        let currentVel = rigidBody!.linearVelocity
        
        rigidBody?.angularFactor = .zero
        rigidBody?.linearVelocity = float3(direction.x, direction.y, currentVel.z)
        
        if playerMovement.isWishJump && isGrounded
        {
            let jumpValue = currentVel.z + 150 * q2b
            
            rigidBody?.linearVelocity = float3(direction.x, direction.y, jumpValue)
        }
        
        if let origin = motionState?.transform.origin
        {
            transform.position = origin * b2q
        }
    }
    
    private func traceGround()
    {
        isGrounded = false
        
        let slopeMaxNormalY: Float = 0.4
        
        for i in 0 ..< scene.world.numberOfManifolds()
        {
            let contact = scene.world.manifold(by: i)
            
            guard contact.numberOfContacts() > 0 else { continue }
            
            let body0 = contact.body0
            let body1 = contact.body1
            
            var sign: Float = 0
            
            if body0 == rigidBody
            {
                sign = 1
            }
            else if body1 == rigidBody
            {
                sign = -1
            }
            else
            {
                continue
            }
            
            let normal = contact.contactPoint(at: 0).normalWorldOnB * sign
            
            if dot(normal, .z_axis) > slopeMaxNormalY
            {
                isGrounded = true
                break
            }
        }
        
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
    
    private func updateInput()
    {
        let deltaTime = GameTime.deltaTime

        playerMovement.forwardmove = 0
        playerMovement.rightmove = 0
        forwardmove = 0
        rightmove = 0
        
        if Keyboard.isKeyPressed(.w)
        {
            playerMovement.forwardmove = 1
            forwardmove = 1
        }

        if Keyboard.isKeyPressed(.s)
        {
            playerMovement.forwardmove = -1
            forwardmove = -1
        }
        
        if Keyboard.isKeyPressed(.a)
        {
            playerMovement.rightmove = -1
            rightmove = -1
        }

        if Keyboard.isKeyPressed(.d)
        {
            playerMovement.rightmove = 1
            rightmove = 1
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
        isWishJump = Keyboard.isKeyPressed(.space)
        
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
