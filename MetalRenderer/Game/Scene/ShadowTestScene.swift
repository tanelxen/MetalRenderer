//
//  ShadowTestScene.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 05.02.2022.
//

class ShadowTestScene: Scene
{
    override func build()
    {
//        let terrain = GameObject(name: "Terrain", mesh: Mesh(modelName: "ground_grass"))
//        terrain.transform.position = float3(0, 0, 0)
//        terrain.transform.scale = float3(100, 0, 100)
//        addChild(terrain)
        
        let room = GameObject(name: "Room", mesh: Mesh(modelName: "room"))
        room.transform.scale = float3(5, 3, 5)
        addChild(room)
        
        let campfire = GameObject(name: "Campfire", mesh: Mesh(modelName: "campfire"))
        campfire.transform.position = float3(2, 0, 0)
        campfire.transform.scale = float3(repeating: 0.5)
        campfire.transform.rotation.y = Float(45).radians
        addChild(campfire)
        
        let flower = GameObject(name: "Flower", mesh: Mesh(modelName: "flower_purpleA"))
        flower.transform.position = float3(-2, 0, 0)
        flower.transform.scale = float3(repeating: 2)
        addChild(flower)
        
//        let well = GameObject(name: "Well", mesh: Mesh(modelName: "well"))
//        well.transform.position = float3(0, 0, 2)
//        addChild(well)
        
        let tree1 = GameObject(name: "Tree1", mesh: Mesh(modelName: "tree_pineTallA_detailed"))
        tree1.transform.position = float3(0, 0, 2)
        addChild(tree1)
        
        let tree2 = GameObject(name: "Tree2", mesh: Mesh(modelName: "tree_pineRoundC"))
        tree2.transform.position = float3(0, 0, -2)
        addChild(tree2)
        
        let axe = GameObject(name: "Axe", mesh: Mesh(modelName: "bedrollFrame"))
        axe.transform.position = float3(0, 2, 0)
//        axe.transform.rotation.x = Float(90).radians
//        axe.transform.rotation.y = Float(90).radians
        addChild(axe)
        
        let light = LightNode()
        light.transform.position = float3(0, 1, 0)
        light.setLight(color: float3(1.0, 0.9, 0.7))
        light.setLight(brightness: 5)
        lights.append(light)
        addChild(light)
    }
    
    override func doUpdate()
    {
    }
}
