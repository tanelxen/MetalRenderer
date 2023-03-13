//
//  Barney.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 18.02.2022.
//

import simd

class Barney
{
    var transform = Transform()
    var mesh: SkeletalMesh?
    
    private var movementSpeed: Float = 90.0
    
    private weak var scene: Q3MapScene?
    
    private var playerMovement = PlayerMovement()
    
    private var isSeePlayer = false
    
    private var route: [float3] = []
    private var routeIndex = -1 // индекс точки в маршруте, к которой мы следуем
    
    init(scene: Q3MapScene)
    {
        self.scene = scene
        self.mesh = SkeletalMesh(name: "barney", ext: "mdl")
        
        mesh?.sequenceName = "walk"
        
        playerMovement.scene = scene
        playerMovement.cl_forwardspeed = 110
    }
    
    func update()
    {
        playerMovement.forwardmove = 0
        
//        look()
        
        updateRoute()
        
        if isSeePlayer
        {
            moveToPlayer(minDist: 128)
        }
        
        playerMovement.transform = transform
        playerMovement.update()
        transform.position = playerMovement.transform.position
        
        if playerMovement.forwardmove != 0
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
    
    private func setSequence(name: String)
    {
        if mesh?.sequenceName != name
        {
            mesh?.sequenceName = name
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
        playerMovement.forwardmove = 1
    }
}
