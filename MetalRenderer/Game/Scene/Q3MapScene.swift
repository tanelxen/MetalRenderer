//
//  Q3MapScene.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.02.2022.
//

import MetalKit

class Q3MapScene: Scene
{
    var bspMesh: BSPMesh?
    
    let scale: Float = 1.0
    
    private var collision: Q3MapCollision!
    
    override func build()
    {
        camera.transform.position = float3(0, 1.0, 0)
        camera.eyeHeight = 1.0
        
        if let url = Bundle.main.url(forResource: "q3dm2", withExtension: "bsp"), let data = try? Data(contentsOf: url)
        {
            let q3map = Q3Map(data: data)
            print("bsp file loaded")
            
            collision = Q3MapCollision(q3map: q3map)
            
            // get spawn points and set camera position to one
            let spawnPoints = q3map.entities.filter { entity in
                entity["classname"] == "info_player_deathmatch"
            }

            if spawnPoints.count > 0
            {
//                let i = Int(arc4random_uniform(UInt32(spawnPoints.count)))
                let entity = spawnPoints[0]

                let origin = entity["origin"]!.split(separator: " ").map { Float($0)! }
//                let angle = Float(entity["angle"]!)!
                
                let position = float3(origin[0], origin[2] + 128, -origin[1]) * scale
//                let rotation = float3(0, Float(90).radians, 0)

                camera.transform.position = position
//                camera.transform.rotation = rotation
            }
            
//            let lightEntities = q3map.entities.filter { entity in
//                entity["classname"] == "light"
//            }
//
//            for entity in lightEntities
//            {
//                let origin = entity["origin"]!.split(separator: " ").map { Float($0)! }
//                let position = float3(origin[0], origin[2], -origin[1]) * scale
//
//                let radius = Float(entity["light"]!)!
//
//                let light = LightNode()
//                light.shouldCastShadow = false
//                light.transform.position = position
//                light.setLight(color: float3(1.0, 0.9, 0.7))
//                light.setLight(brightness: radius)
//                lights.append(light)
//
//                addChild(light)
//            }
            
            bspMesh = BSPMesh(device: Engine.device, map: q3map)
            print("bsp mesh created")
        }
        
//        if let url = Bundle.main.url(forResource: "barney", withExtension: "mdl"), let data = try? Data(contentsOf: url)
//        {
//            let mdl = HLModel(data: data)
//            print("mdl file loaded")
//        }
    }
    
    override func render(with encoder: MTLRenderCommandEncoder?, useMaterials: Bool)
    {
        var sceneUniforms = sceneConstants
        var modelConstants = ModelConstants()
        modelConstants.modelMatrix.scale(axis: float3(repeating: scale))
        
        encoder?.setVertexBytes(&sceneUniforms, length: SceneConstants.stride, index: 1)
        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        bspMesh?.renderWithEncoder(encoder!, time: 0)
        
        super.render(with: encoder, useMaterials: true)
    }
    
    override func doUpdate()
    {
        let start = camera.transform.position
        var end = camera.desiredPosition
        
        end.y -= 80 * GameTime.deltaTime
        
        camera.transform.position = collision.traceSphere(start: start, end: end, inputRadius: 64)
    }
}
