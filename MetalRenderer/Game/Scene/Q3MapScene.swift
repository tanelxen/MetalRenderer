//
//  Q3MapScene.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.02.2022.
//

import MetalKit
//import Assimp

class Q3MapScene: Scene
{
    private var bspMesh: BSPMesh?
    
    private var staticMesh: StaticMesh?
    
    private var collision: Q3MapCollision!
    
    private var entities: [Barney] = []
    
    private let navigation = NavigationGraph()
    
    private (set) var player: Player?
    
    private var canUpdate = false
    
    init()
    {
        super.init(name: "Q3MapScene")
    }
    
    override func build()
    {
        if let url = Bundle.main.url(forResource: "q3dm7", withExtension: "bsp"), let data = try? Data(contentsOf: url)
        {
            loadMap(with: data)
        }
        
        navigation.load(named: "q3dm7")
    }
    
    private func loadMap(with data: Data)
    {
        let q3map = Q3Map(data: data)
        print("bsp file loaded")

        collision = Q3MapCollision(q3map: q3map)

        // get spawn points and set camera position to one
        let spawnPoints = q3map.entities.filter { entity in
            entity["classname"] == "info_player_deathmatch"
        }
        
        for i in 0 ..< spawnPoints.count
        {
            let spawnPoint = spawnPoints[i]
            let origin = spawnPoint["origin"]!.split(separator: " ").map { Float($0)! }
            let angle = Float(spawnPoint["angle"]!)!
            
            let transform = Transform()
            transform.position = float3(origin[0], origin[1], origin[2])
            transform.rotation = Rotator(pitch: 0, yaw: angle, roll: 0)
            
            if i == 0
            {
                player = Player(scene: self)
                player?.transform = transform
                player?.posses()
            }
//            else
//            {
//                let barney = Barney(scene: self)
//                barney.transform = transform
//
//                entities.append(barney)
//            }
        }

        bspMesh = BSPMesh(device: Engine.device, map: q3map)
        print("bsp mesh created")
        
        Keyboard.onKeyDown = { key in
            
            if key == .q
            {
                self.makeWaypoint()
            }
            
            if key == .e
            {
                self.removeWaypoint()
            }
            
            if key == .r
            {
                self.navigation.save(named: "q3dm7")
            }
        }
    }
    
    func renderWorld(with encoder: MTLRenderCommandEncoder?)
    {
        var sceneUniforms = sceneConstants
        var modelConstants = ModelConstants()
        
        encoder?.setVertexBytes(&sceneUniforms, length: SceneConstants.stride, index: 1)
        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        bspMesh?.renderWithEncoder(encoder!)
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
    
    func renderSkeletalMeshes(with encoder: MTLRenderCommandEncoder?)
    {
        var sceneUniforms = self.sceneConstants
        encoder?.setVertexBytes(&sceneUniforms, length: SceneConstants.stride, index: 1)
        
        for entity in entities
        {
            entity.update()
            
            entity.transform.updateModelMatrix()
            
            var modelMatrix = entity.transform.matrix
            modelMatrix.translate(direction: float3(0, 0, -25))
            
            var modelConstants = ModelConstants(modelMatrix: modelMatrix)
            encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
            
            entity.mesh?.renderWithEncoder(encoder!)
        }
    }
    
    func renderPlayer(with encoder: MTLRenderCommandEncoder?)
    {
        var sceneUniforms = self.sceneConstants
        encoder?.setVertexBytes(&sceneUniforms, length: SceneConstants.stride, index: 1)
        
        if let player = player
        {
            let transform = player.camera.transform
            
            var modelMatrix = matrix_identity_float4x4
            
            modelMatrix.rotate(angle: -transform.rotation.pitch.radians, axis: .y_axis)
            modelMatrix.rotate(angle: -transform.rotation.yaw.radians, axis: .z_axis)
            
            modelMatrix.translate(direction: -transform.position)
            
            modelMatrix = modelMatrix.inverse
            
            modelMatrix.translate(direction: float3(-2, 4, 0))
            
            var modelConstants = ModelConstants(modelMatrix: modelMatrix)
            encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
            
            player.mesh?.renderWithEncoder(encoder!)
        }
    }
    
    func renderWaypoints(with encoder: MTLRenderCommandEncoder?)
    {
        var sceneUniforms = self.sceneConstants
        encoder?.setVertexBytes(&sceneUniforms, length: SceneConstants.stride, index: 1)
        
        navigation.render(with: encoder)
    }
    
    func trace(start: float3, end: float3) -> Bool
    {
        var hitResult = HitResult()
        collision.traceRay(result: &hitResult, start: end, end: start)
        
        return hitResult.fraction >= 1
    }
    
    func trace(start: float3, end: float3, mins: float3, maxs: float3) -> HitResult
    {
        var hitResult = HitResult()
        collision.traceBox(result: &hitResult, start: start, end: end, mins: mins, maxs: maxs)
        
        return hitResult
    }
    
    override func doUpdate()
    {
        player?.update()
    }
    
    private func makeWaypoint()
    {
        let forward = CameraManager.shared.mainCamera.transform.rotation.forward
        
        let start = CameraManager.shared.mainCamera.transform.position
        let end = start + forward * 1024
        
        var hitResult = HitResult()
        collision.traceRay(result: &hitResult, start: start, end: end)
        
        if hitResult.fraction != 1
        {
            let waypoint = Waypoint()
            waypoint.transform.position = hitResult.endpos
            waypoint.transform.position.z += waypoint.maxBounds.z
            
            navigation.add(waypoint)
        }
    }
    
    private func removeWaypoint()
    {
        let start = CameraManager.shared.mainCamera.transform.position
        let dir = CameraManager.shared.mainCamera.transform.rotation.forward
        
        let index = navigation.findIntersectedByRay(start: start, dir: dir, dist: 256)
        
        if index != -1
        {
            navigation.remove(at: index)
        }
    }
    
    private func clickMouse(at: float2)
    {
    }
}

func intersection(orig: float3, dir: float3, mins: float3, maxs: float3, t: Float) -> Bool
{
    var dirfrac = float3()
    
    dirfrac.x = 1.0 / dir.x
    dirfrac.y = 1.0 / dir.y
    dirfrac.z = 1.0 / dir.z
    
    let tx1 = (mins.x - orig.x) * dirfrac.x
    let tx2 = (maxs.x - orig.x) * dirfrac.x

    var tmin = min(tx1, tx2)
    var tmax = max(tx1, tx2)

    let ty1 = (mins.y - orig.y) * dirfrac.y
    let ty2 = (maxs.y - orig.y) * dirfrac.y

    tmin = max(tmin, min(ty1, ty2))
    tmax = min(tmax, max(ty1, ty2))

    let tz1 = (mins.z - orig.z) * dirfrac.z
    let tz2 = (maxs.z - orig.z) * dirfrac.z

    tmin = max(tmin, min(tz1, tz2))
    tmax = min(tmax, max(tz1, tz2))

    return tmax >= max(0, tmin) && tmin < t
}
