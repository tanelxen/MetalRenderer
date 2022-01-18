//
//  SandboxScene.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 17.01.2022.
//

class SandboxScene: Scene
{
    var well: GameObject!
    var sphere: GameObject!
    
    let light = LightNode()
    
    override func build()
    {
        camera.transform.position.z = 5
        camera.transform.position.y = 2
        
        well = makeWell()
        well.transform.position.z = -2
        well.transform.rotation.y = Float(65).radians
        
        let chest = makeChest()
        chest.transform.scale = float3(repeating: 0.02)
        chest.transform.position = float3(2, 0, 2)
        
        let skull = makeSkull()
        skull.transform.rotation.x = Float(-90).radians
        skull.transform.position = float3(0, 10, 0)
        
        chest.addChild(skull)
        
        well.addChild(chest)
        
        sphere = makeSphere()
        sphere.transform.position = float3(0, 2, 0)
        sphere.transform.scale = float3(repeating: 0.1)
        sphere.addChild(light)
        
//        light.transform.position = float3(0, 2, 0)
        light.setLight(color: float3(0.8, 0.8, 0.8))
        light.setLight(ambientIntensity: 0.1)
        
        lights.append(light)
        
        addChild(well)
        addChild(sphere)
//        addChild(light)
    }
    
    override func doUpdate()
    {
        if Mouse.IsMouseButtonPressed(.left)
        {
            let dx = Mouse.getDX()
            let dy = Mouse.getDY()
            
            well.transform.rotation.x += dy * GameTime.deltaTime
            well.transform.rotation.y += dx * GameTime.deltaTime
        }
        
        if Keyboard.isKeyPressed(.q)
        {
            sphere.transform.position.x -= GameTime.deltaTime
        }
        
        if Keyboard.isKeyPressed(.e)
        {
            sphere.transform.position.x += GameTime.deltaTime
        }
        
//        sphere.transform.position = light.transform.position
    }
    
    private func makeSkull() -> GameObject
    {
        let mesh = Mesh(modelName: "skull")

        mesh.material.setTexture(.skull)
        mesh.material.setMaterial(isLit: true)
        mesh.material.setMaterial(ambient: float3(0.1, 0.1, 0.1))
        
        return GameObject(mesh: mesh)
    }
    
    private func makeSphere() -> GameObject
    {
        let mesh = Mesh(modelName: "sphere")

        mesh.material.setMaterial(isLit: false)
        mesh.material.setColor(float4(0.8, 0.8, 0.2, 1.0))
        
        return GameObject(mesh: mesh)
    }
    
    private func makeChest() -> GameObject
    {
        let mesh = Mesh(modelName: "chest")

        mesh.material.setMaterial(isLit: true)
        mesh.material.setMaterial(ambient: float3(0.1, 0.1, 0.1))
        
        return GameObject(mesh: mesh)
    }
    
    private func makeWell() -> GameObject
    {
        let mesh = Mesh(modelName: "well")

        mesh.material.setMaterial(isLit: true)
        mesh.material.setMaterial(ambient: float3(0.1, 0.1, 0.1))
        
        return GameObject(mesh: mesh)
    }
}

