//
//  Player.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 19.02.2022.
//

import simd
import Foundation
import SwiftBullet

class Player
{
    var transform = Transform()
    var mesh: SkeletalMesh?
    
    let camera = PlayerCamera()
    
    private var rotateSpeed: Float = 30.0
    
    private var velocity: float3 = .zero
    
    private weak var scene: BrushScene!
    
    private let footsteps = ["pl_step1.wav",
                             "pl_step2.wav",
                             "pl_step3.wav",
                             "pl_step4.wav"]
    
    private let shootTimer: TimerManager
    
    private var bobing: Float = 0.0
    
    private (set) var motionState: BulletMotionState?
    private (set) var rigidBody: BulletRigidBody?
    
    private let q2b: Float = 2.54 / 100
    private let b2q: Float = 100 / 2.54
    
    private var forwardmove: Float = 0.0
    private var rightmove: Float = 0.0
    private var isWishJump = false
    
    private var isGrounded = false
    
    private var pickConstraint: BulletPoint2PointConstraint?
    
    init(scene: BrushScene)
    {
        self.scene = scene
        
        if let url = ResourceManager.getURL(for: "Assets/models/v_9mmhandgun/mesh.skl")
        {
            self.mesh = SkeletalMesh(url: url)
        }
        
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
        let shape = BulletCapsuleShape(radius: 15 * q2b, height: 28 * q2b, up: .y)
        
        let startTransform = BulletTransform()
        startTransform.setIdentity()
        startTransform.origin = transform.position * q2b
        
        let mass: Float = 1.0
        let localInertia = shape.calculateLocalInertia(mass: mass)
        
        let motionState = BulletMotionState(transform: startTransform)
        
        let body = BulletRigidBody(mass: mass,
                                   motionState: motionState,
                                   collisionShape: shape,
                                   localInertia: localInertia)
        
        body.forceActivationState(.disableDeactivation)
        body.friction = 0
        
        scene.physicsWorld.add(rigidBody: body)
        
        self.motionState = motionState
        self.rigidBody = body
    }
    
    private func setupEvents()
    {
        Mouse.onLeftMouseDown = { [weak self] in
            self?.shootTimer.start { [weak self] in
                self?.makeShoot()
            }
        }

        Mouse.onLeftMouseUp = { [weak self] in
            self?.shootTimer.stop()
        }
        
//        Keyboard.onKeyDown = { [weak self] key in
//            if key == .e {
//                self?.grab()
//            }
//        }
    }
    
    func update()
    {
        updateInput()
        updateBtMovement()
        
        camera.transform.position = transform.position + float3(0, 40, 0)
        camera.transform.rotation = transform.rotation
        
//        if let constraint = self.pickConstraint
//        {
//            let start = camera.transform.position
//            let end = start + camera.transform.rotation.forward * 96
//
//            constraint.setPivotB(end * q2b)
//        }
    }
    
    // Movement based on Bullet's rigid body
    private func updateBtMovement()
    {
        traceGround()
        
        var forward = transform.rotation.forward
        var right = transform.rotation.right
        
        forward.y = 0
        right.y = 0
        
        var direction: float3 = .zero
        direction += forward * forwardmove * 200 * q2b
        direction += right * rightmove * 150 * q2b
        
        let currentVel = rigidBody!.linearVelocity
        
        rigidBody?.angularFactor = .zero
        rigidBody?.linearVelocity = float3(direction.x, currentVel.y, direction.z)
        
        if isWishJump && isGrounded
        {
            let jumpValue = currentVel.y + 150 * q2b
            
            rigidBody?.linearVelocity = float3(direction.x, jumpValue, direction.z)
        }
        
        if let origin = motionState?.getWorldTransform().origin
        {
            transform.position = origin * b2q
        }
    }
    
    private func traceGround()
    {
        isGrounded = false
        
        let slopeMaxNormalY: Float = 0.4
        
        for i in 0 ..< scene.physicsWorld.numberOfManifolds()
        {
            let contact = scene.physicsWorld.manifold(by: i)
            
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
            
            if dot(normal, .y_axis) > slopeMaxNormalY
            {
                isGrounded = true
                break
            }
        }
        
    }
    
//    private func grab()
//    {
//        guard pickConstraint == nil else {
//            scene.world.remove(pickConstraint!)
//            pickConstraint = nil
//            return
//        }
//        
//        let start = camera.transform.position
//        let end = start + camera.transform.rotation.forward * 128
//        
//        let dynHit = scene.world.rayTestClosest(
//            from: start * q2b,
//            to: end * q2b,
//            collisionFilterGroup: 0b1111111,
//            collisionFilterMask: 0b1111111
//        )
//        
//        if dynHit.hasHits, !dynHit.node.isStaticObject
//        {
//            dynHit.node.setDeactivationEnabled(false)
//            
//            let constraint = BulletPoint2PointConstraint(nodeA: dynHit.node, pivotA: .zero)
//            
//            scene.world.add(constraint, disableCollisionsBetweenLinkedBodies: true)
//            
//            pickConstraint = constraint
//        }
//    }
//    
    private func makeShoot()
    {
        AudioEngine.play(file: "pl_gun3.wav")
        
        mesh?.sequenceName = "shoot"
        let duration = Double(mesh?.cur_anim_duration ?? 0)

        Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { timer in
            self.mesh?.sequenceName = "idle3"
        }
        
//        let start = camera.transform.position
//        let end = start + camera.transform.rotation.forward * 1024
        
//        scene.makeShoot(start: start, end: end)
    }
    
    private func updateInput()
    {
        let deltaTime = GameTime.deltaTime

        forwardmove = 0
        rightmove = 0
        
        if Keyboard.isKeyPressed(.w)
        {
            forwardmove = 1
        }

        if Keyboard.isKeyPressed(.s)
        {
            forwardmove = -1
        }
        
        if Keyboard.isKeyPressed(.a)
        {
            rightmove = -1
        }

        if Keyboard.isKeyPressed(.d)
        {
            rightmove = 1
        }
        
        isWishJump = Keyboard.isKeyPressed(.space)
        
        transform.rotation.yaw += Mouse.getDX() * rotateSpeed * deltaTime
        transform.rotation.pitch -= Mouse.getDY() * rotateSpeed * deltaTime
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
