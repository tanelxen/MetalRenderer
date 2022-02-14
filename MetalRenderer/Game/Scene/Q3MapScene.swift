//
//  Q3MapScene.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.02.2022.
//

import MetalKit
import Assimp

class Q3MapScene: Scene
{
    var bspMesh: BSPMesh?
    var staticMesh: StaticMesh?
    
    let scale: Float = 1.0
    
    private var collision: Q3MapCollision!
    
    override func build()
    {
        camera.transform.position = float3(0, 1.0, 0)
        camera.eyeHeight = 1.0
        
        if let url = Bundle.main.url(forResource: "q3dm0", withExtension: "bsp"), let data = try? Data(contentsOf: url)
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
                let angle = Float(entity["angle"]!)!.radians
                
                let position = float3(origin[0], origin[2] + 60, -origin[1]) * scale
                let rotation = float3(0, angle, 0)

                camera.transform.position = position
                camera.transform.rotation = rotation
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
        
//        if let url = Bundle.main.url(forResource: "police", withExtension: "smd")
//        {
//            let path = url.path
//
//            let scene = try? AiScene.init(file: path)
//
//            print(scene?.meshes.first?.faces)
//        }
        
        staticMesh = StaticMesh(name: "skull", ext: "obj")
    }
    
    override func render(with encoder: MTLRenderCommandEncoder?, useMaterials: Bool)
    {
        var sceneUniforms = sceneConstants
        var modelConstants = ModelConstants()
//        modelConstants.modelMatrix.scale(axis: float3(repeating: scale))
        
        encoder?.setVertexBytes(&sceneUniforms, length: SceneConstants.stride, index: 1)
        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        bspMesh?.renderWithEncoder(encoder!)
        
        super.render(with: encoder, useMaterials: true)
    }
    
    func renderStaticMeshes(with encoder: MTLRenderCommandEncoder?)
    {
        var sceneUniforms = sceneConstants
        var modelConstants = ModelConstants()
        modelConstants.modelMatrix.scale(axis: float3(repeating: 1))
        
        encoder?.setVertexBytes(&sceneUniforms, length: SceneConstants.stride, index: 1)
        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        staticMesh?.renderWithEncoder(encoder!)
    }
    
    override func doUpdate()
    {
//        let start = camera.transform.position
//
//        let end = start - float3(0, 0.25, 0)
//
//        var hitResult = HitResult()
//
//        let playerMins = float3(-15, -24, -15)
//        let playerMaxs = float3(15, 32, 15)
//
//        collision.traceBox(result: &hitResult, start: start, end: end, mins: playerMins, maxs: playerMaxs)
//
//        var normals: [float3] = []
//        var timeLeft = GameTime.deltaTime
//
//        var velocity = camera.velocity
////        velocity.y -= 80 * GameTime.deltaTime
//
//        if let normal = hitResult.plane?.normal
//        {
//            let overbounce: Float = 1.001
//
//            var backoff = dot(velocity, normal)
//
//            if backoff < 0
//            {
//                backoff *= overbounce;
//            }
//            else
//            {
//                backoff /= overbounce;
//            }
//
//            velocity = velocity - normal * backoff
//
//            normals.append(normal)
//        }
//
//        for _ in 0 ..< 4
//        {
//            var i: Int = 0
//
//            let end = camera.transform.position + velocity * timeLeft
//
//            var work = HitResult()
//            collision.traceBox(result: &work, start: start, end: end, mins: playerMins, maxs: playerMaxs)
//
//            if work.fraction > 0
//            {
//                camera.transform.position = work.point
//            }
//
//            if work.fraction == 1 { break }
//
//            timeLeft -= timeLeft * work.fraction
//
//            if normals.count >= 5
//            {
//                velocity = .zero
//                return
//            }
//
//            for normal in normals
//            {
//                if dot(work.normal!, normal) > 0.99
//                {
//                    velocity += work.normal!
//                    break
//                }
//            }
//
//            if i < normals.count { continue }
//
//            if let normal = work.normal
//            {
//                normals.append(normal)
//                i += 1
//            }
//        }
        
        camera.transform.position += camera.velocity
    }
}
