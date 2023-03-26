//
//  Q3MapScene.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.02.2022.
//

import MetalKit

class Q3MapScene
{
    private (set) var sceneConstants = SceneConstants()
    
    private let skybox = Skybox()
    
    private var bspMesh: BSPMesh?
    
    private var staticMesh: StaticMesh?
    
    private var collision: Q3MapCollision!
    
    private var entities: [Barney] = []
    
    private let navigation = NavigationGraph()
    
    private (set) var player: Player?
    
    private var isReady = false
    
    init()
    {
        HudView.shared.gameState = .loading
        
        DispatchQueue.global().async {
            self.build()
        }
    }
    
    private func build()
    {
        if let data = ResourceManager.getData(for: "Assets/q3/maps/q3dm7.bsp")
        {
            loadMap(with: data)
        }
        
        DispatchQueue.global().async {
            self.navigation.load(named: "q3dm7")
            self.navigation.scene = self
            self.navigation.build()
        }
    }
    
    private func spawn(with q3map: Q3Map)
    {
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
            else if i == 6
            {
                let barney = Barney(scene: self)
                barney.transform = transform

                entities.append(barney)
            }
        }
        
        print("entities were created")
    }
    
    private func loadMap(with data: Data)
    {
        let q3map = Q3Map(data: data)
        print("bsp file was loaded")
        
        bspMesh = BSPMesh(map: q3map)
        print("bsp mesh was created")

        collision = Q3MapCollision(q3map: q3map)
        print("collision was created")
        
        DispatchQueue.global().async {
            self.spawn(with: q3map)
            
            DispatchQueue.main.async {
                self.isReady = true
                HudView.shared.gameState = .ready
                AudioEngine.start()
                AudioEngine.play(file: "Half-Life13.mp3")
            }
        }
        
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
                self.navigation.build()
                self.navigation.save(named: "q3dm7")
            }
            
            if key == .n
            {
                let start = self.entities.first!.transform.position
                let end = self.player!.transform.position
                
                let route = self.navigation.makeRoute(from: start, to: end)
                
                self.entities.first!.moveBy(route: route)
            }
        }
    }
    
    func renderSky(with encoder: MTLRenderCommandEncoder?)
    {
        guard isReady else { return }
        
        var sceneUniforms = sceneConstants
        
        encoder?.setVertexBytes(&sceneUniforms, length: SceneConstants.stride, index: 1)

        skybox.renderWithEncoder(encoder!)
    }
    
    func renderWorldLightmapped(with encoder: MTLRenderCommandEncoder?)
    {
        guard isReady else { return }
        
        var sceneUniforms = sceneConstants
        var modelConstants = ModelConstants()
        
        encoder?.setVertexBytes(&sceneUniforms, length: SceneConstants.stride, index: 1)
        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        bspMesh?.renderLightmapped(with: encoder!)
    }
    
    func renderWorldVertexlit(with encoder: MTLRenderCommandEncoder?)
    {
        guard isReady else { return }
        
        var sceneUniforms = sceneConstants
        var modelConstants = ModelConstants()
        
        encoder?.setVertexBytes(&sceneUniforms, length: SceneConstants.stride, index: 1)
        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        bspMesh?.renderVertexlit(with: encoder!)
    }
    
    func renderStaticMeshes(with encoder: MTLRenderCommandEncoder?)
    {
        guard isReady else { return }
        
        var sceneUniforms = sceneConstants
        var modelConstants = ModelConstants()
        modelConstants.modelMatrix.scale(axis: float3(repeating: 1))
        
        encoder?.setVertexBytes(&sceneUniforms, length: SceneConstants.stride, index: 1)
        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        staticMesh?.renderWithEncoder(encoder!)
    }
    
    func renderSkeletalMeshes(with encoder: MTLRenderCommandEncoder?)
    {
        guard isReady else { return }
        
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
        
        renderPlayer(with: encoder)
    }
    
    private func renderPlayer(with encoder: MTLRenderCommandEncoder?)
    {
        guard isReady else { return }
        
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
        guard isReady else { return }
        
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
    
    final func update()
    {
        guard isReady else { return }
        
        CameraManager.shared.update()
        
        // Update game logic
        doUpdate()
        
        updateSceneConstants()
    }
    
    private func doUpdate()
    {
        player?.update()
    }
    
    private func updateSceneConstants()
    {
        let camera = CameraManager.shared.mainCamera
        
        sceneConstants.viewMatrix = camera.viewMatrix
        sceneConstants.projectionMatrix = camera.projectionMatrix
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
