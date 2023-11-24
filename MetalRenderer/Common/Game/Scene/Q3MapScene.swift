//
//  Q3MapScene.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.02.2022.
//

import Foundation
import MetalKit
import SwiftZip
import BulletSwift

class Q3MapScene
{
    private let skybox = Skybox()
    
    private var worldMesh: WorldStaticMesh?
    
    private var collision: Q3MapCollision!
    private var brushesCollision: BrushCollision!
    
    private var lightGrid: Q3MapLightGrid?
    
    private (set) var spawnPoints: [Transform] = []
    private var entities: [Barney] = []
    
    private let navigation = NavigationGraph()
    
    private (set) var player: Player?
    
    private (set) var isReady = false
    
    private (set) var isPlaying = false
    
    private (set) static var current: Q3MapScene!
    
    private (set) var brushes: BrushRenderer?
    
    var onReady: (()->Void)?
    
    private let world = BulletWorld()
    
    private var colliderTransform = Transform()
    private var colliderMotion: MotionState?
    
    init(url: URL)
    {
        do
        {
            worldMesh = WorldStaticMesh()
            
            let archive = try ZipArchive(url: url)
            
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
                        
                        brushesCollision = BrushCollision()
                        brushesCollision.loadFromAsset(asset)
                        
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
        }
        catch
        {
            print("\(error)")
        }
        
        isReady = true
        Q3MapScene.current = self
        
        world.gravity = vector3(0, 0, -10)
        
        createFloor()
        createCollider()
        
        colliderTransform.scale = float3(30, 30, 30)
        
        if let position = colliderMotion?.transform.origin
        {
            colliderTransform.position = position
        }
        
        Debug.shared.addCube(transform: colliderTransform, color: float4(1, 0, 0, 1))
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
        
        world.stepSimulation(timeStep: 1.0/60.0, maxSubSteps: 10, fixedTimeStep: 1.0/60.0)
        
        if let position = colliderMotion?.transform.origin
        {
            colliderTransform.position = position
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
            
            let shape = BulletBoxShape(halfExtents: vector3(15, 15, 32))
                
            let transform = BulletTransform()
            transform.setIdentity()
            transform.origin = point.position
            
            let motionState = MotionState(transform: transform)
            
            let body = BulletRigidBody(mass: 0,
                                       motionState: motionState,
                                       collisionShape: shape)
            
            world.add(rigidBody: body)
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
//        var hitResult = HitResult()
//        collision.traceRay(result: &hitResult, start: start, end: end)
//
//        let line = Intersection.Line(start: start, end: hitResult.endpos)
//
//        let aabbs = entities.map {
//            Intersection.AABB(
//                mins: $0.minBounds + $0.transform.position,
//                maxs: $0.maxBounds + $0.transform.position
//            )
//        }
//
//        if let result = Intersection.findIntersection(line: line, aabbs: aabbs)
//        {
//            Particles.shared.addParticles(origin: result.point, dir: result.normal, count: 5)
//            entities[result.index].takeDamage()
//        }
//        else if hitResult.fraction > 0, let normal = hitResult.plane?.normal
//        {
//            Decals.shared.addDecale(origin: hitResult.endpos, normal: normal)
//            Particles.shared.addParticles(origin: hitResult.endpos, dir: normal, count: 5)
//        }
        
        let dynHit = world.rayTestClosest(from: start, to: end, collisionFilterGroup: 1, collisionFilterMask: 1)
        
        if dynHit.hasHits
        {
            let force = normalize(end - start) * 1000
            dynHit.node.applyForce(force, onPoint: dynHit.hitPos)
        }
        
        let statHit = world.rayTestClosest(from: start, to: end, collisionFilterGroup: 0, collisionFilterMask: 0)
        
        if statHit.hasHits
        {
            Decals.shared.addDecale(origin: statHit.hitPos, normal: statHit.hitNormal)
            Particles.shared.addParticles(origin: statHit.hitPos, dir: statHit.hitNormal, count: 5)
        }
    }
    
    func createFloor()
    {
        for brush in brushesCollision.brushes
        {
            let shape = BulletConvexHullShape()
            
            for point in brush.vertices
            {
                shape.addPoint(point)
            }
            
            let transform = BulletTransform()
            transform.setIdentity()
            transform.origin = vector3(0, 0, 0)
            
            let motionState = MotionState(transform: transform)
            let body = BulletRigidBody(mass: 0,
                                       motionState: motionState,
                                       collisionShape: shape)
            world.add(rigidBody: body)
        }
    }
    
    func createCollider()
    {
//        let colShape = BulletBoxShape(halfExtents: vector3(15, 15, 15))
        let colShape = BulletSphereShape(radius: 15)
        
        let startTransform = BulletTransform()
        startTransform.setIdentity()
        
        let mass: Float = 1.0
        let localInertia = colShape.calculateLocalInertia(mass: mass)
        
//        startTransform.origin = vector3(256, 1180, 200)
        startTransform.origin = float3(140, 1443, 100)
        
        let colMotionState = MotionState(transform: startTransform)
        
        let colBody = BulletRigidBody(mass: mass,
                                      motionState: colMotionState,
                                      collisionShape: colShape,
                                      localInertia: localInertia)
        
        world.add(rigidBody: colBody)
        
        self.colliderMotion = colMotionState
    }
}

protocol BulletMotionState {
  func getWorldTransform() -> BulletTransform
  func setWorldTransform(centerOfMassWorldTransform: BulletTransform)
}

class MotionState: BulletMotionState
{
    var transform = BulletTransform()

    init(transform: BulletTransform) {
        self.transform = transform
    }

    func getWorldTransform() -> BulletTransform {
        return transform
    }

    func setWorldTransform(centerOfMassWorldTransform: BulletTransform) {
        self.transform = centerOfMassWorldTransform
    }
}

extension BulletRigidBody {
  convenience init(mass: Float, motionState: BulletMotionState, collisionShape: BulletCollisionShape, localInertia: vector_float3 = vector_float3(0, 0, 0)) {
    self.init(mass: mass,
              motionStateGetWorldTransform: { () -> BulletTransform in
                return motionState.getWorldTransform()
              },
              motionStateSetWorldTransform: { (transform) in
                motionState.setWorldTransform(centerOfMassWorldTransform: transform)
              },
              collisionShape: collisionShape,
              localInertia: localInertia)
  }
}

extension BulletWorld {
  
  @discardableResult
  func stepSimulation(timeStep: Float, maxSubSteps: Int = 1, fixedTimeStep: Float = Float(1.0/60.0)) -> Int {
    return Int(__stepSimulation(withTimeStep: timeStep, maxSubSteps: Int32(maxSubSteps), fixedTimeStep: fixedTimeStep))
  }
  
  func add(rigidBody: BulletRigidBody, collisionFilterGroup: Int32, collisionFilterMask: Int32) {
    __add(rigidBody, withCollisionFilterGroup: collisionFilterGroup, collisionFilterMask: collisionFilterMask)
  }
  
  func add(rigidBody: BulletRigidBody) {
    __add(rigidBody)
  }
  
  func remove(rigidBody: BulletRigidBody) {
    __remove(rigidBody)
  }
  
  func add(ghost: BulletGhostObject) {
    __addGhost(ghost)
  }
  
  func remove(ghost: BulletGhostObject) {
    __removeGhost(ghost)
  }
  
}

extension BulletCollisionShape {
  func calculateLocalInertia(mass: Float) -> vector_float3 {
    return __calculateLocalInertia(withMass: mass)
  }
}
