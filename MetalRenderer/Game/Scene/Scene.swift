//
//  Scene.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

class Scene
{
    private let name: String
    
    private let root = Node(name: "SceneRoot");
    
    private (set) var sceneConstants = SceneConstants()
    let camera = DebugCamera.shared
    
    var lights: [LightNode] = []
    
    init(name: String = "Scene")
    {
        self.name = name
        
        build()
        
        root.frustumTest = false
        root.updateTransform()
    }
    
    func build() { }
    
    final func update()
    {
        // Update game logic
        doUpdate()
        
        camera.update(deltaTime: GameTime.deltaTime)
        
        updateSceneConstants()
        
        root.update()
    }
    
    /// Override this function instead of the update function
    func doUpdate() { }
    
    func addChild(_ child: Node)
    {
        root.addChild(child)
    }
    
    func render(with encoder: MTLRenderCommandEncoder?, useMaterials: Bool)
    {
        encoder?.setVertexBytes(&sceneConstants, length: SceneConstants.stride, index: 1)
        
        root.render(with: encoder, useMaterials: useMaterials)
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
