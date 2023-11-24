//
//  Barney.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 18.02.2022.
//

import Foundation
import simd

class Barney
{
    var transform = Transform()
    var mesh: SkeletalMesh?
    
    let minBounds = float3( -15, -15, -32 )
    let maxBounds = float3( 15, 15, 32 )
    
    private var movementSpeed: Float = 90.0
    
    private weak var scene: Q3MapScene?
    
    private var playerMovement = PlayerMovement()
    private var forwardmove: Float = 0
    private var cl_forwardspeed: Float = 0
    
    private var isSeePlayer = false
    
    private var route: [float3] = []
    private var routeIndex = -1 // индекс точки в маршруте, к которой мы следуем
    
    private let footsteps = ["pl_step1.wav",
                             "pl_step2.wav",
                             "pl_step3.wav",
                             "pl_step4.wav"]
    
    private let hurt = ["donthurtem.wav"]
    
    private var curentSequence = "idle1"
    
    init(scene: Q3MapScene)
    {
        self.scene = scene
        
        if let url = ResourceManager.getURL(for: "Assets/models/barney/mesh.skl")
        {
            self.mesh = SkeletalMesh(url: url)
        }
        
        playerMovement.scene = scene
        playerMovement.cl_forwardspeed = 110
        
        playerMovement.playStepsSound = { [weak self] in
            if let footstep = self?.footsteps.randomElement() {
                AudioEngine.play(file: footstep)
            }
        }
    }
    
    func update()
    {
        forwardmove = 0
        
//        look()
        
        updateRoute()
        
        if isSeePlayer
        {
            moveToPlayer(minDist: 128)
        }
        
        playerMovement.transform = transform
        playerMovement.update()
        transform.position = playerMovement.transform.position
        
        let direction = transform.rotation.forward * forwardmove * cl_forwardspeed
        transform.position += direction * GameTime.deltaTime
        
        
        if forwardmove != 0
        {
            setSequence(name: "walk")
        }
        else
        {
            setSequence(name: "idle1")
        }
    }
    
    func moveBy(route: [float3])
    {
        self.route = route
        self.routeIndex = 0
    }
    
    func takeDamage()
    {
        if let sound = hurt.randomElement() {
            AudioEngine.play(file: sound)
        }
    }
    
    private func setSequence(name: String)
    {
        if mesh?.sequenceName != name
        {
            mesh?.sequenceName = name
            cl_forwardspeed = (mesh?.groundSpeed ?? 0)
        }
    }
    
    private func look()
    {
        guard let player = scene?.player else { return }
        
        let myEye = transform.position + float3(0, 0, 64)
        let playerEye = player.transform.position + float3(0, 0, 64)

        isSeePlayer = scene!.trace(start: myEye, end: playerEye)
    }
    
    private func updateRoute()
    {
        guard route.count > 0 else { return }
        guard routeIndex != -1 else { return }
        
        if routeIndex >= route.count
        {
            routeIndex = -1
            return
        }
        
        let start = transform.position
        let end = route[routeIndex]
        
        if length(end - start) < 32
        {
            routeIndex += 1
            return
        }
        
        let dir = normalize(end - start)
        
        transform.rotation.yaw = atan2(dir.y, dir.x).degrees
        moveForward()
    }
    
    private func moveToPlayer(minDist: Float)
    {
        guard let player = scene?.player else { return }
        
        let myEye = transform.position + float3(0, 0, 64)
        let playerEye = player.transform.position + float3(0, 0, 64)
        
        let vectorToPlayer = playerEye - myEye
        let dir = normalize(vectorToPlayer)
        
        transform.rotation.yaw = atan2(dir.y, dir.x).degrees
        
        if length(vectorToPlayer) > minDist
        {
            moveForward()
        }
    }
    
    private func moveForward()
    {
        forwardmove = 1
    }
}
