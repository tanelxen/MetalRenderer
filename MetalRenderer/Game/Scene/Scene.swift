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
    
    var octree: Octree<String>?
    
    init(name: String = "Scene")
    {
        self.name = name
        
        build()
        
        root.frustumTest = false
        root.updateTransform()
        
        buildOctree()
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
    
    func buildOctree()
    {
        let boxMin = float3(-500, 0, -500)
        let boxMax = float3(500, 10, 500)
        let box = Box(boxMin: boxMin, boxMax: boxMax)
        
        octree = Octree<String>(boundingBox: box, minimumCellSize: 5.0)
        
        for node in root.children
        {
            octree?.add(node.name, at: node.transform.position)
        }
        
//        print(octree)
    }
    
    func render(with encoder: MTLRenderCommandEncoder?, useMaterials: Bool)
    {
        encoder?.setVertexBytes(&sceneConstants, length: SceneConstants.stride, index: 1)
        
        root.render(with: encoder, useMaterials: useMaterials)
    }
    
    func renderBoundingBoxes(with encoder: MTLRenderCommandEncoder?)
    {
        encoder?.setVertexBytes(&sceneConstants, length: SceneConstants.stride, index: 1)
        
        for node in root.children
        {
            if node.frustumTest && !node.isVisible { continue }
            
            encoder?.pushDebugGroup(node.name)
            node.renderBoundingBox(with: encoder)
            encoder?.popDebugGroup()
        }
    }
    
    func renderOctree(with encoder: MTLRenderCommandEncoder?)
    {
        encoder?.setVertexBytes(&sceneConstants, length: SceneConstants.stride, index: 1)
        
        octree?.render(with: encoder)
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
