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
    
    let scale: Float = 0.1
    
    override func build()
    {
        camera.transform.position = float3(0, 1.0, 0)
        camera.eyeHeight = 1.0
        
        if let url = Bundle.main.url(forResource: "q3dm5", withExtension: "bsp"), let data = try? Data(contentsOf: url)
        {
            let q3map = Q3Map(data: data)
            print("bsp file loaded")
            
            
            // get spawn points and set camera position to one
            let spawnPoints = q3map.entities.filter { entity in
                entity["classname"] == "info_player_deathmatch"
            }

            if spawnPoints.count > 0
            {
//                let i = Int(arc4random_uniform(UInt32(spawnPoints.count)))
                let entity = spawnPoints[0]
//                let angle = Float(entity["angle"]!)!
                let origin = entity["origin"]!.split(separator: " ").map { Float($0)! }
                
                let position = float3(origin[0], origin[2] + 5, -origin[1]) * scale

                camera.transform.position = position
//                camera.yaw = angle
            }
            
            for entity in spawnPoints
            {
                let origin = entity["origin"]!.split(separator: " ").map { Float($0)! }
                let position = float3(origin[0], origin[2] + 5, -origin[1]) * scale
                
                let light = LightNode()
                light.shouldCastShadow = false
                light.transform.position = position
                light.setLight(color: float3(1.0, 0.9, 0.7))
                light.setLight(brightness: 10)
                lights.append(light)
                
                addChild(light)
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
    }
    
    override func render(with encoder: MTLRenderCommandEncoder?, useMaterials: Bool)
    {
        var sceneUniforms = sceneConstants
        var modelConstants = ModelConstants()
        modelConstants.modelMatrix.scale(axis: float3(repeating: scale))
        
        encoder?.setVertexBytes(&sceneUniforms, length: SceneConstants.stride, index: 1)
        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        bspMesh?.material.apply(to: encoder)
        
        bspMesh?.renderWithEncoder(encoder!, time: 0)
        
        super.render(with: encoder, useMaterials: true)
    }
}
