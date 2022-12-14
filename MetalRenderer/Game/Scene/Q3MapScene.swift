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
                transform.position = float3(origin[0], origin[1], origin[2])
                transform.rotation = Rotator(pitch: 0, yaw: angle, roll: 0)
                
                if i == 1
                {
                    transform.position.z += 1
                    
                    let player = Player(scene: self)
                    player.transform = transform
                    player.posses()

                    self.player = player
                }
                else
                {
                    transform.position.z -= 25
                    
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
        
//        modelConstants.modelMatrix = matrix_float4x4(rows: [
//            float4(1, 0, 0, 0),
//            float4(0, 0, 1, 0),
//            float4(0, -1, 0, 0),
//            float4(0, 0, 0, 1)
//        ])
        
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
    
    func trace(start: float3, end: float3, mins: float3, maxs: float3) -> HitResult
    {
        var hitResult = HitResult()
        collision.traceBox(result: &hitResult, start: start, end: end, mins: mins, maxs: maxs)
        
        return hitResult
    }
    
    override func doUpdate()
    {
        player?.update()
    }
}
