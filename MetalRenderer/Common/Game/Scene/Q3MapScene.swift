//
//  Q3MapScene.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.02.2022.
//

import Foundation
import MetalKit
import SwiftZip

class Q3MapScene
{
    let name: String
    
    private let skybox = Skybox()
    
    private var worldMesh: WorldStaticMesh?
    
//    private var collision: Q3MapCollision!
    
    private var lightGrid: Q3MapLightGrid?
    
    private (set) var spawnPoints: [Transform] = []
    private var entities: [Barney] = []
    
    private let navigation = NavigationGraph()
    
    private (set) var player: Player?
    
    private (set) var isReady = false
    
    private (set) var isPlaying = false
    
    private (set) static var current: Q3MapScene!
    
//    private (set) var brushes: BrushRenderer?
    
    let kdTree = KdTree()
    let octree = Octree()
    let bspTree = BSPTree()
    let hashGrid = HashGrid()
    
    var onReady: (()->Void)?
    
    init(url: URL)
    {
        name = url.deletingPathExtension().lastPathComponent
        
        do
        {
            let archive = try ZipArchive(url: url)
            
            var lightmap: MTLTexture?
            
            for entry in archive.entries()
            {
                // Get basic entry information
                let name = try entry.getName()
                let data = try entry.data()
                
                if name == "worldmesh.bin"
                {
                    if let asset = WorldStaticMeshAsset.load(from: data)
                    {
                        worldMesh = WorldStaticMesh()
                        worldMesh?.loadFromAsset(asset)
                    }
                }
                
                if name == "lightmap.png"
                {
                    lightmap = TextureManager.shared.getTexture(data: data, SRGB: false)
                }
                
                if name == "collision.json"
                {
                    let decoder = JSONDecoder()
                    
                    if let asset = try? decoder.decode(WorldCollisionAsset.self, from: data)
                    {
//                        collision = Q3MapCollision(asset: asset)
                        
//                        kdTree.loadFromAsset(asset)
//                        octree.loadFromAsset(asset)
                        hashGrid.loadFromAsset(asset)
//                        bspTree.loadFromAsset(asset)
                        
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
            }
            
            worldMesh?.setLightmap(lightmap)
        }
        catch
        {
            print("\(error)")
        }
        
        isReady = true
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
        octree.traceBox(result: &hitResult, start: start, end: end, mins: .zero, maxs: .zero)
        
        return hitResult.fraction >= 1
    }
    
    func trace(start: float3, end: float3, mins: float3, maxs: float3) -> HitResult
    {
        var hitResult = HitResult()
        hashGrid.traceBox(result: &hitResult, start: start, end: end, mins: mins, maxs: maxs)

        return hitResult
    }
}

extension Q3MapScene
{
    func makeShoot(start: float3, end: float3)
    {
        var hitResult = HitResult()
        octree.traceBox(result: &hitResult, start: start, end: end, mins: .zero, maxs: .zero)
        
        if hitResult.fraction > 0, let normal = hitResult.plane?.normal
        {
            Decals.shared.addDecale(origin: hitResult.endpos, normal: normal)
            Particles.shared.addParticles(origin: hitResult.endpos, dir: normal, count: 5)
        }
    }
}
