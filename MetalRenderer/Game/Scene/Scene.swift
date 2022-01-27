//
//  Scene.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

class Scene: Node
{
    private (set) var sceneConstants = SceneConstants()
    let camera = DebugCamera.shared
    
    internal var lights: [LightNode] = []
    
    init()
    {
        super.init(name: "Scene")
        build()
        frustumTest = false
    }
    
    func build() { }
    
    override func update()
    {
        camera.update(deltaTime: GameTime.deltaTime)
        
        updateSceneConstants()
        
        super.update()
    }
    
    override func render(with encoder: MTLRenderCommandEncoder?)
    {
        encoder?.setVertexBytes(&sceneConstants, length: SceneConstants.stride, index: 1)
        
        // Lights
        var lightDatas: [LightData] = lights.map { $0.lightData }
        var lightCount = lights.count
        
        encoder?.setFragmentBytes(&lightDatas, length: LightData.stride * lightCount, index: 2)
        encoder?.setFragmentBytes(&lightCount, length: Int32.size, index: 3)
        
        super.render(with: encoder)
    }
    
    private func updateSceneConstants()
    {
        sceneConstants.viewMatrix = camera.viewMatrix
        
        sceneConstants.skyViewMatrix = camera.viewMatrix
        
        sceneConstants.skyViewMatrix[3] = .zero
        
        sceneConstants.projectionMatrix = camera.projectionMatrix
        
        sceneConstants.cameraPosition = camera.transform.position
    }
}
