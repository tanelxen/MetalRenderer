//
//  LightNode.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

class LightNode: Node
{
    private (set) var lightData = LightData()
    
    override init(name: String = "Light")
    {
        super.init(name: name)
    }

    override func update()
    {
//        doUpdate()
        lightData.position = transform.position
    }
}

extension LightNode
{
    func setLight(color: float3)
    {
        lightData.color = color
    }
    
    func setLight(brightness: Float)
    {
        lightData.brightness = brightness
    }
    
    func setLight(ambientIntensity: Float)
    {
        lightData.ambientIntensity = ambientIntensity
    }
}
