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
    
    private var isSeePlayer = false
    
    init(scene: Q3MapScene)
    {
        self.scene = scene
        self.mesh = SkeletalMesh(name: "barney", ext: "mdl")
    }
    
    func update()
    {
//        look()
        
        if isSeePlayer
        {
            moveToPlayer(minDist: 128)
        }
    }
    
    private func look()
    {
        guard let player = scene?.player else { return }
        
        let myEye = transform.position + float3(0, 0, 64)
        let playerEye = player.transform.position + float3(0, 0, 64)

        isSeePlayer = scene!.trace(start: myEye, end: playerEye)
    }
    
    private func moveToPlayer(minDist: Float)
    {
        guard let player = scene?.player else { return }
        
        let myEye = transform.position + float3(0, 0, 64)
        let playerEye = player.transform.position + float3(0, 0, 64)
        
        let vectorToPlayer = playerEye - myEye
        let dir = normalize(vectorToPlayer)
        
        if length(vectorToPlayer) > minDist
        {
            transform.position += dir * (movementSpeed * GameTime.deltaTime)
        }
        
        let angle = atan2(dir.y, dir.x).degrees
        
        transform.rotation.yaw = angle
    }
}
