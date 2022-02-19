//
//  SponzaScene.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 05.02.2022.
//

class SponzaScene: Scene
{
    override func build()
    {
        let sponza = GameObject(name: "Sponza", mesh: Mesh(modelName: "sponza"))
        sponza.transform.scale = float3(repeating: 0.01)
        addChild(sponza)
        
        let well = GameObject(name: "Well", mesh: Mesh(modelName: "well"))
        well.transform.position = float3(2, 0, 0)
        well.transform.scale = float3(repeating: 0.5)
        addChild(well)
        
        let light = LightNode()
        light.transform.position = float3(0, 2, 0)
        light.setLight(color: float3(1.0, 0.9, 0.7))
        light.setLight(brightness: 6)
        lights.append(light)
        addChild(light)
    }
}
