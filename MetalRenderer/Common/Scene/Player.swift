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
    let camera = PlayerCamera()
    
    private var rotateSpeed: Float = 30.0
    
    private var velocity: float3 = .zero
    
    private weak var scene: World!
    
    private (set) var motionState: BulletMotionState?
    private (set) var rigidBody: BulletRigidBody?
    
    private let q2b: Float = 2.54 / 100
    private let b2q: Float = 100 / 2.54
    
    private var forwardmove: Float = 0.0
    private var rightmove: Float = 0.0
    private var isWishJump = false
    
    private var isGrounded = false
    
    private var pickConstraint: BulletPoint2PointConstraint?
    
    init(scene: World)
    {
        self.scene = scene
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
    
    func update()
    {
        updateInput()
        updateBtMovement()
        
        camera.transform.position = transform.position + float3(0, 40, 0)
        camera.transform.rotation = transform.rotation
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
