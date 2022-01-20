//
//  SkySphere.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 18.01.2022.
//

import Foundation

class SkySphere: GameObject
{
    init(textureType: TextureTypes = .skysphere)
    {
        let mesh = Mesh(modelName: "skysphere")
        
        let material = Material()
        
//        material.pipelineStateType = .skysphere
        
        if let texture = TextureLibrary[.skysphere]
        {
            material.setBaseColorMap(texture)
        }
        
        mesh.customMaterial = material
        
        super.init(name: "SkySphere", mesh: mesh)
        
        transform.scale = float3(100, 100, 100)
        frustumTest = false
    }
}
