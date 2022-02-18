//
//  Barney.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 18.02.2022.
//

import MetalKit

class Barney
{
    var transform = Transform()
    var mesh: SkeletalMesh?
    
    private var movementSpeed: Float = 90.0
    
    private weak var scene: Q3MapScene?
    
    init(scene: Q3MapScene)
    {
        self.scene = scene
        self.mesh = SkeletalMesh(name: "barney", ext: "mdl")
    }
    
    func update()
    {
//        if let scene = self.scene
//        {
//            let isSeePlayer = scene.trace(start: transform.position, end: DebugCamera.shared.transform.position)
//
//            print("isSeePlayer", isSeePlayer)
//        }
        
        var eyePos = transform.position
        eyePos.y += 64
        
        let vectorToPlayer = DebugCamera.shared.transform.position - eyePos
        let dir = normalize(vectorToPlayer)
        
        if length(vectorToPlayer) > 128
        {
            transform.position += dir * (movementSpeed * GameTime.deltaTime)
        }
        
        let angle = atan2(dir.x, dir.z)
        
        transform.rotation.y = angle - 0.5 * Float.pi
    }
}
