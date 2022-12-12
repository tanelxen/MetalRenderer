//
//  Q3MapScene.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.02.2022.
//

import MetalKit
//import Assimp

class Q3MapScene: Scene
{
    private var bspMesh: BSPMesh?
    
    private var staticMesh: StaticMesh?
    
    private var collision: Q3MapCollision!
    
    private var entities: [Barney] = []
    
    private (set) var player: Player?
    
    init()
    {
        super.init(name: "Q3MapScene")
    }
    
    override func build()
    {
        if let url = Bundle.main.url(forResource: "q3dm1", withExtension: "bsp"), let data = try? Data(contentsOf: url)
        {
            let q3map = Q3Map(data: data)
            print("bsp file loaded")

            collision = Q3MapCollision(q3map: q3map)

            // get spawn points and set camera position to one
            let spawnPoints = q3map.entities.filter { entity in
                entity["classname"] == "info_player_deathmatch"
            }
            
            for i in 0 ..< spawnPoints.count
            {
                let spawnPoint = spawnPoints[i]
                let origin = spawnPoint["origin"]!.split(separator: " ").map { Float($0)! }
                let angle = Float(spawnPoint["angle"]!)!
                
                let transform = Transform()
                transform.position = float3(origin[0], origin[2] - 25, -origin[1])
                transform.rotation = float3(0, angle, 0)
                
                if i == 0
                {
                    let player = Player(scene: self)
                    player.transform = transform
                    player.posses()

                    self.player = player
                }
                else
                {
                    let barney = Barney(scene: self)
                    barney.transform = transform
                    
                    entities.append(barney)
                }
            }

            bspMesh = BSPMesh(device: Engine.device, map: q3map)
            print("bsp mesh created")
        }
    }
    
    func renderWorld(with encoder: MTLRenderCommandEncoder?)
    {
        var sceneUniforms = sceneConstants
        var modelConstants = ModelConstants()
//        modelConstants.modelMatrix.scale(axis: float3(repeating: scale))
        
        encoder?.setVertexBytes(&sceneUniforms, length: SceneConstants.stride, index: 1)
        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        bspMesh?.renderWithEncoder(encoder!)
    }
    
    func renderStaticMeshes(with encoder: MTLRenderCommandEncoder?)
    {
        var sceneUniforms = sceneConstants
        var modelConstants = ModelConstants()
        modelConstants.modelMatrix.scale(axis: float3(repeating: 1))
        
        encoder?.setVertexBytes(&sceneUniforms, length: SceneConstants.stride, index: 1)
        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        staticMesh?.renderWithEncoder(encoder!)
    }
    
    func renderSkeletalMeshes(with encoder: MTLRenderCommandEncoder?)
    {
        var sceneUniforms = self.sceneConstants
        encoder?.setVertexBytes(&sceneUniforms, length: SceneConstants.stride, index: 1)
        
        for entity in entities
        {
            entity.update()
            
            entity.transform.updateModelMatrix()
            
            var modelConstants = ModelConstants(modelMatrix: entity.transform.matrix)
            encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
            
            entity.mesh?.renderWithEncoder(encoder!)
        }
    }
    
    func trace(start: float3, end: float3) -> Bool
    {
        var hitResult = HitResult()
        collision.traceRay(result: &hitResult, start: end, end: start)
        
        return hitResult.fraction >= 1
    }
    
    override func doUpdate()
    {
        player?.update()
        
//        let start = camera.transform.position
//
//        let end = start - float3(0, 0.25, 0)
//
//        var hitResult = HitResult()
//
//        let playerMins = float3(-15, -24, -15)
//        let playerMaxs = float3(15, 32, 15)
//
//        collision.traceBox(result: &hitResult, start: start, end: end, mins: playerMins, maxs: playerMaxs)
//
//        var normals: [float3] = []
//        var timeLeft = GameTime.deltaTime
//
//        var velocity = camera.velocity
////        velocity.y -= 80 * GameTime.deltaTime
//
//        if let normal = hitResult.plane?.normal
//        {
//            let overbounce: Float = 1.001
//
//            var backoff = dot(velocity, normal)
//
//            if backoff < 0
//            {
//                backoff *= overbounce;
//            }
//            else
//            {
//                backoff /= overbounce;
//            }
//
//            velocity = velocity - normal * backoff
//
//            normals.append(normal)
//        }
//
//        for _ in 0 ..< 4
//        {
//            var i: Int = 0
//
//            let end = camera.transform.position + velocity * timeLeft
//
//            var work = HitResult()
//            collision.traceBox(result: &work, start: start, end: end, mins: playerMins, maxs: playerMaxs)
//
//            if work.fraction > 0
//            {
//                camera.transform.position = work.point
//            }
//
//            if work.fraction == 1 { break }
//
//            timeLeft -= timeLeft * work.fraction
//
//            if normals.count >= 5
//            {
//                velocity = .zero
//                return
//            }
//
//            for normal in normals
//            {
//                if dot(work.normal!, normal) > 0.99
//                {
//                    velocity += work.normal!
//                    break
//                }
//            }
//
//            if i < normals.count { continue }
//
//            if let normal = work.normal
//            {
//                normals.append(normal)
//                i += 1
//            }
//        }
        
//        var start = entities[0].transform.position
//        start.y += 64
//
//        let end = camera.transform.position
//
//        var hitResult = HitResult()
//        collision.traceRay(result: &hitResult, start: start, end: end)
//
//        print("hitResult.fraction", hitResult.fraction)
    }
}
