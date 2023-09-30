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
    
    init(url: URL)
    {
        do
        {
            let data = try Data(contentsOf: url)
            
            DispatchQueue.global().async {
                self.loadMap(with: data)
            }
        }
        catch
        {
            print(error.localizedDescription)
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
//            break
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

extension Q3MapScene
{
    func makeShoot(start: float3, end: float3)
    {
        var hitResult = HitResult()
        collision.traceRay(result: &hitResult, start: start, end: end)
        
        let line = Intersection.Line(start: start, end: hitResult.endpos)
        
        let aabbs = entities.map {
            Intersection.AABB(
                mins: $0.minBounds + $0.transform.position,
                maxs: $0.maxBounds + $0.transform.position
            )
        }
        
        if let result = Intersection.findIntersection(line: line, aabbs: aabbs)
        {
            Particles.shared.addParticles(origin: result.point, dir: result.normal, count: 5)
            entities[result.index].takeDamage()
        }
        else if hitResult.fraction > 0, let normal = hitResult.plane?.normal
        {
            Decals.shared.addDecale(origin: hitResult.endpos, normal: normal)
            Particles.shared.addParticles(origin: hitResult.endpos, dir: normal, count: 5)
        }
    }
}
