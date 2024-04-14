//
//  Q3MapScene.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.02.2022.
//

import Foundation
import MetalKit
import SwiftZip
import DetourPathfinder

class Q3MapScene
{
    private let skybox = Skybox()
    
    private var worldMesh: WorldStaticMesh?
    
    private var collision: Q3MapCollision!
    
    private var lightGrid: Q3MapLightGrid?
    
    private (set) var spawnPoints: [Transform] = []
    private var entities: [Barney] = []
    
    private (set) var player: Player?
    
    private (set) var isReady = false
    
    private (set) var isPlaying = false
    
    private (set) static var current: Q3MapScene!
    
    private (set) var brushes: BrushRenderer?
//    private let navigation = NavigationGraph()
    private (set) var navigation: NavigationMesh?
    
    var onReady: (()->Void)?
    
    init(url: URL)
    {
        do
        {
            worldMesh = WorldStaticMesh()
            
            let archive = try ZipArchive(url: url)
            
            var pathfinder: DetourPathfinder?
            
            for entry in archive.entries()
            {
                // Get basic entry information
                let name = try entry.getName()
                let data = try entry.data()
                
                if name == "worldmesh.bin"
                {
                    if let asset = WorldStaticMeshAsset.load(from: data)
                    {
                        worldMesh?.loadFromAsset(asset)
                    }
                }
                
                if name == "lightmap.png"
                {
                    let lightmap = TextureManager.shared.getTexture(data: data, SRGB: false)
                    worldMesh?.setLightmap(lightmap)
                }
                
                if name == "collision.json"
                {
                    let decoder = JSONDecoder()
                    
                    if let asset = try? decoder.decode(WorldCollisionAsset.self, from: data)
                    {
                        collision = Q3MapCollision(asset: asset)
                        
//                        brushes = BrushRenderer()
//                        brushes?.loadFromAsset(asset)
                    }
                }
                
                if name == "entities.json"
                {
                    let decoder = JSONDecoder()
                    
                    if let asset = try? decoder.decode(WorldEntitiesAsset.self, from: data)
                    {
                        spawnPoints = asset.entities
                            .filter({ $0.classname == "info_player_deathmatch" || $0.classname == "info_player_start" })
                            .map {
                                let transform = Transform()
                                transform.position = $0.position
                                transform.rotation = Rotator(pitch: 0, yaw: $0.rotation.z, roll: 0)
                                
                                return transform
                            }
                        
//                        for entity in asset.entities
//                        {
//                            if entity.classname == "light"
//                            {
//                                Billboards.shared.addBillboard(origin: entity.position, image: "Assets/point_light_img.png")
//                            }
//
//                            if entity.classname == "misc_model"
//                            {
//                                Billboards.shared.addBillboard(origin: entity.position, image: "Assets/3d_model_img.png")
//                            }
//                        }
                    }
                }

                if name == "navmesh.json"
                {
                    navigation = NavigationMesh(data: data)
                }
                
                if name == "detour.bin"
                {
                    pathfinder = DetourPathfinder()
                    pathfinder?.load(from: data)
                }
            }
            
            navigation?.pathfinder = pathfinder
        }
        catch
        {
            print("\(error)")
        }
        
        isReady = true
        Q3MapScene.current = self
        
        Keyboard.onKeyDown = { key in
            
            if key == .n
            {
                self.moveBarneyToPlayer()
            }
        }
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
    
    private func moveBarneyToPlayer()
    {
        guard let start = entities.first?.transform.position else { return }
        guard let end = player?.transform.position else { return }
        guard let navigation = navigation else { return }
        
        let route = navigation.makeRoute(from: start, to: end)
        
        Debug.shared.clear()
        
        for point in route
        {
            let trans = Transform()
            trans.position = point
            trans.scale = float3(repeating: 6)

            Debug.shared.addCube(transform: trans, color: float4(1, 0, 1, 0.5))
        }
        
        entities.first?.moveBy(route: route)
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
}

extension Q3MapScene
{
    func renderSky(with encoder: MTLRenderCommandEncoder?)
    {
        guard isReady else { return }
        
        skybox.renderWithEncoder(encoder!)
        encoder?.setFragmentTexture(nil, index: 0)
    }
    
    func renderWorldLightmapped(with encoder: MTLRenderCommandEncoder?)
    {
        guard isReady else { return }
        
//        var modelConstants = ModelConstants()
//        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        worldMesh?.renderLightmapped(with: encoder!)
    }
    
    func renderWorldVertexlit(with encoder: MTLRenderCommandEncoder?)
    {
//        guard isReady else { return }
//
//        var modelConstants = ModelConstants()
//        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
//
//        bspMesh?.renderVertexlit(with: encoder!)
    }
    
    func renderStaticMeshes(with encoder: MTLRenderCommandEncoder?)
    {
        guard isReady else { return }
        
        navigation?.renderWithEncoder(encoder!)
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
            
            let ambient = lightGrid?.ambient(at: entity.transform.position) ?? float3(1, 1, 1)
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
        
        let ambient = lightGrid?.ambient(at: transform.position) ?? float3(1, 1, 1)
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
