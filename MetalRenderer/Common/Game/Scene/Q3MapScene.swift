//
//  Q3MapScene.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.02.2022.
//

import Foundation
import MetalKit
import Quake3BSP

class Q3MapScene
{
    private (set) var map: Q3Map?
    
    private let skybox = Skybox()
    
    private var bspMesh: BSPMesh?
    
    private var collision: Q3MapCollision!
    
    private var lightGrid: Q3MapLightGrid!
    
    private (set) var spawnPoints: [Transform] = []
    private var entities: [Barney] = []
    
    private let navigation = NavigationGraph()
    
    private (set) var player: Player?
    
    private (set) var isReady = false
    
    private (set) var isPlaying = false
    
    private (set) static var current: Q3MapScene!
    
    var onReady: (()->Void)?
    
    private var mapName: String
    
    init(name: String)
    {
        mapName = name
        
        DispatchQueue.global().async {
            self.build()
        }
        
        Q3MapScene.current = self
    }
    
    func startPlaying(in viewport: Viewport)
    {
        guard !isPlaying else { return }
        
        isPlaying = true
        
        AudioEngine.play(file: "Half-Life13.mp3")
        
        DispatchQueue.global().async {
            self.spawnBarneys()
        }
        
        spawnPlayer()
        
        if let camera = self.player?.camera
        {
            viewport.camera = camera
        }
    }
    
    func stopPlaying()
    {
        guard isPlaying else { return }
        
        isPlaying = false
        
        AudioEngine.stopAllSounds()
        
        player = nil
    }
    
    func update()
    {
        guard isReady else { return }
        
        if isPlaying
        {
            player?.update()
        }
        
        Particles.shared.update()
    }
    
    private func build()
    {
        if let data = ResourceManager.getData(for: "Assets/q3/maps/\(mapName).bsp")
        {
            loadMap(with: data)
            
//            let url = ResourceManager.URLInDocuments(for: "\(mapName).obj")
//            map?.saveAsOBJ(url: url)
        }
        
//        DispatchQueue.global().async {
//            self.navigation.load(named: "q3dm7")
//            self.navigation.scene = self
//            self.navigation.build()
//        }
    }
    
    private func fetchSpawnPoints(for q3map: Q3Map)
    {
        let info_players = q3map.entities.filter { entity in
            entity["classname"] == "info_player_deathmatch"
        }
        
        for i in 0 ..< info_players.count
        {
            let info = info_players[i]
            let origin = info["origin"]!.split(separator: " ").map { Float($0)! }
            let angle = Float(info["angle"]!)!
            
            let transform = Transform()
            transform.position = float3(origin[0], origin[1], origin[2])
            transform.rotation = Rotator(pitch: 0, yaw: angle, roll: 0)
            
            spawnPoints.append(transform)
        }
    }
    
    private func spawnPlayer()
    {
        guard let point = spawnPoints.first else { return }
        
        player = Player(scene: self)
        player?.transform.position = point.position
        player?.transform.rotation = point.rotation
    }
    
    private func spawnBarneys()
    {
        entities.removeAll()
        
        for point in spawnPoints.dropFirst()
        {
            let barney = Barney(scene: self)
            barney.transform.position = point.position
            barney.transform.rotation = point.rotation

            entities.append(barney)
            break
        }
    }
    
    private func loadMap(with data: Data)
    {
        let q3map = Q3Map(data: data)
        print("bsp file was loaded")
        
        fetchSpawnPoints(for: q3map)
        print("spawn points were created")
        
        bspMesh = BSPMesh(map: q3map)
        print("bsp mesh was created")

        collision = Q3MapCollision(q3map: q3map)
        print("collision was created")
        
        lightGrid = Q3MapLightGrid(
            minBounds: q3map.models.first!.mins,
            maxBounds: q3map.models.first!.maxs,
            colors: q3map.lightgrid.map({ $0.ambient })
        )
        print("light grid was created")
        
        map = q3map
        
        DispatchQueue.main.async {
            self.isReady = true
            self.onReady?()
        }
    }
}

extension Q3MapScene
{
    func renderSky(with encoder: MTLRenderCommandEncoder?)
    {
        guard isReady else { return }
        
        skybox.renderWithEncoder(encoder!)
    }
    
    func renderWorldLightmapped(with encoder: MTLRenderCommandEncoder?)
    {
        guard isReady else { return }
        
        var modelConstants = ModelConstants()
        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        bspMesh?.renderLightmapped(with: encoder!)
    }
    
    func renderWorldVertexlit(with encoder: MTLRenderCommandEncoder?)
    {
        guard isReady else { return }
        
        var modelConstants = ModelConstants()
        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        bspMesh?.renderVertexlit(with: encoder!)
    }
    
    func renderStaticMeshes(with encoder: MTLRenderCommandEncoder?)
    {
        guard isReady else { return }
        
        var modelConstants = ModelConstants()
        modelConstants.color = float4(0, 1.0, 0.0, 0.5)
//        modelConstants.modelMatrix.scale(axis: float3(repeating: 1))
        
        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
    }
    
    func renderSkeletalMeshes(with encoder: MTLRenderCommandEncoder?)
    {
        guard isReady else { return }
        
        for entity in entities
        {
            entity.update()
            
            entity.transform.updateModelMatrix()
            
            var modelMatrix = entity.transform.matrix
            modelMatrix.translate(direction: float3(0, 0, -25))
            
            let ambient = lightGrid.ambient(at: entity.transform.position)
            let color = float4(ambient, 1.0)
            
            var modelConstants = ModelConstants(modelMatrix: modelMatrix, color: color)
            encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
            
            entity.mesh?.renderWithEncoder(encoder!)
        }
        
        if isPlaying
        {
            renderPlayer(with: encoder)
        }
    }
    
    private func renderPlayer(with encoder: MTLRenderCommandEncoder?)
    {
        guard isReady else { return }
        
        guard let player = self.player else { return }
        
        let transform = player.camera.transform
        
        var modelMatrix = matrix_identity_float4x4
        
        modelMatrix.rotate(angle: -transform.rotation.pitch.radians, axis: .y_axis)
        modelMatrix.rotate(angle: -transform.rotation.yaw.radians, axis: .z_axis)
        
        modelMatrix.translate(direction: -transform.position)
        
        modelMatrix = modelMatrix.inverse
        
        modelMatrix.translate(direction: float3(-2, 4, 0))
        
        let ambient = lightGrid.ambient(at: transform.position)
        let color = float4(ambient, 1.0)
        
        var modelConstants = ModelConstants(modelMatrix: modelMatrix, color: color)
        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        player.mesh?.renderWithEncoder(encoder!)
    }
}

extension Q3MapScene
{
    func trace(start: float3, end: float3) -> Bool
    {
        var hitResult = HitResult()
        collision.traceRay(result: &hitResult, start: start, end: end)
        
        return hitResult.fraction >= 1
    }
    
    func trace2(start: float3, end: float3) -> HitResult
    {
        var hitResult = HitResult()
        collision.traceRay(result: &hitResult, start: start, end: end)
        
        return hitResult
    }
    
    func trace(start: float3, end: float3, mins: float3, maxs: float3) -> HitResult
    {
        var hitResult = HitResult()
        collision.traceBox(result: &hitResult, start: start, end: end, mins: mins, maxs: maxs)
        
        return hitResult
    }
}

//extension Q3MapScene
//{
//    private func makeWaypoint()
//    {
//        let ray = CameraManager.shared.mainCamera.mousePositionInWorld()
//        
//        let start = ray.origin
//        let end = start + ray.direction * 1024
//        
//        var hitResult = HitResult()
//        collision.traceRay(result: &hitResult, start: start, end: end)
//        
//        if hitResult.fraction != 1
//        {
//            let waypoint = Waypoint()
//            waypoint.transform.position = hitResult.endpos
//            //            waypoint.transform.position.z += waypoint.maxBounds.z
//            
//            navigation.add(waypoint)
//        }
//    }
//    
//    private func removeWaypoint()
//    {
//        let ray = CameraManager.shared.mainCamera.mousePositionInWorld()
//        
//        let index = navigation.findIntersectedByRay(start: ray.origin, dir: ray.direction, dist: 1024)
//        
//        if index != -1
//        {
//            navigation.remove(at: index)
//        }
//    }
//}
//
//func intersection(orig: float3, dir: float3, mins: float3, maxs: float3, t: Float) -> Bool
//{
//    var dirfrac = float3()
//    
//    dirfrac.x = 1.0 / dir.x
//    dirfrac.y = 1.0 / dir.y
//    dirfrac.z = 1.0 / dir.z
//    
//    let tx1 = (mins.x - orig.x) * dirfrac.x
//    let tx2 = (maxs.x - orig.x) * dirfrac.x
//
//    var tmin = min(tx1, tx2)
//    var tmax = max(tx1, tx2)
//
//    let ty1 = (mins.y - orig.y) * dirfrac.y
//    let ty2 = (maxs.y - orig.y) * dirfrac.y
//
//    tmin = max(tmin, min(ty1, ty2))
//    tmax = min(tmax, max(ty1, ty2))
//
//    let tz1 = (mins.z - orig.z) * dirfrac.z
//    let tz2 = (maxs.z - orig.z) * dirfrac.z
//
//    tmin = max(tmin, min(tz1, tz2))
//    tmax = min(tmax, max(tz1, tz2))
//
//    return tmax >= max(0, tmin) && tmin < t
//}
