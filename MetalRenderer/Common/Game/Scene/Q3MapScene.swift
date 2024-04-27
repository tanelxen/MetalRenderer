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
import SwiftBullet
import SceneKit

class Q3MapScene
{
    private let skybox = Skybox()
    
    private var worldMesh: WorldStaticMesh?
    
    private var collision: Q3MapCollision!
    private var brushesCollision: BrushCollision!
    
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
    
    let world = BulletWorld()
    
    private var pinkCubeTransform = Transform()
    private (set) var pinkCubeMotion: BulletMotionState?
    
    private var rampTransform: Transform?
    private var rampMotion: BulletMotionState?
    
    private var playerTransform = Transform()
    
    private let q2b: Float = 2.54 / 100
    private let b2q: Float = 100 / 2.54
    
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
                        
                        brushes = BrushRenderer()
                        brushes?.loadFromAsset(asset)
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
                
                if name == "detour.bin"
                {
                    navigation = NavigationMesh(detour: data)
                }
            }
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

        world.gravity = vector3(0, 0, -800 * q2b)
        
        createWorldStaticCollision()
        createPinkCube()
//        createRamp()
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
        
        if let transform = pinkCubeMotion?.getWorldTransform()
        {
            pinkCubeTransform.position = transform.origin * b2q
            
            let quat = simd_quatf(vector: transform.rotation)
            
            let n = SCNNode()
            n.simdOrientation = quat
            let rotation = n.simdEulerAngles
            
            pinkCubeTransform.rotation.pitch = rotation.x.degrees
            pinkCubeTransform.rotation.yaw = rotation.z.degrees
            pinkCubeTransform.rotation.roll = rotation.y.degrees
        }
        
        if let transform = rampMotion?.getWorldTransform()
        {
            rampTransform?.position = transform.origin * b2q
            
            let quat = simd_quatf(vector: transform.rotation)
            
            let n = SCNNode()
            n.simdOrientation = quat
            let rotation = n.simdEulerAngles
            
            rampTransform?.rotation.pitch = rotation.x.degrees
            rampTransform?.rotation.yaw = rotation.z.degrees
            rampTransform?.rotation.roll = rotation.y.degrees
        }
        
        world.stepSimulation(timeStep: GameTime.deltaTime, maxSubSteps: 10)
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
    
    func routeToPlayer(from position: float3) -> [float3]
    {
        guard let end = player?.transform.position else { return [] }
        guard let navigation = navigation else { return [] }
        
        return navigation.makeRoute(from: position, to: end)
    }
    
    private func spawnPlayer()
    {
        guard let point = spawnPoints.first else { return }
        
        let transform = Transform()
        transform.position = point.position
        transform.rotation = point.rotation
        
        player = Player(scene: self)
        player?.spawn(with: transform)
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
        }
    }
    
    deinit {
        world.removeAllConstraints()
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

        worldMesh?.renderLightmapped(with: encoder!)
    }
    
    func renderWorldVertexlit(with encoder: MTLRenderCommandEncoder?)
    {
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
            encoder?.setVertexBytes(&modelConstants, length: MemoryLayout<ModelConstants>.size, index: 2)
            
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
        encoder?.setVertexBytes(&modelConstants, length: MemoryLayout<ModelConstants>.size, index: 2)
        
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
        
//        if start == end
//        {
//            collision.traceBox(result: &hitResult, start: start, end: end, mins: mins, maxs: maxs)
//        }
//        else
//        {
//            let shape = BulletBoxShape(halfExtents: float3(15, 15, 28) * q2b)
//
//            let dynHit = world.convexTestClosest(
//                from: start * q2b,
//                to: end * q2b,
//                shape: shape,
//                collisionFilterGroup: 0b1111111,
//                collisionFilterMask: 0b1111110
//            )
//
//            hitResult.fraction = dynHit.hitFraction
//            hitResult.endpos = start + hitResult.fraction * (end - start)
//            hitResult.plane = WorldCollisionAsset.Plane(normal: dynHit.hitNormal, distance: 0)
//        }
        
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
    
    private func createWorldStaticCollision()
    {
        for brush in brushesCollision.brushes
        {
            let shape = BulletConvexHullShape()
            
            for point in brush.vertices
            {
                shape.addPoint(point * q2b)
            }
            
            let transform = BulletTransform()
            transform.setIdentity()
            
            let motionState = BulletMotionState(transform: transform)
            let body = BulletRigidBody(mass: 0,
                                       motionState: motionState,
                                       collisionShape: shape)
            body.friction = 0.5
            world.add(rigidBody: body)
        }
    }
    
    private func createPinkCube()
    {
        let colShape = BulletBoxShape(halfExtents: vector3(15, 15, 15) * q2b)

        let startTransform = BulletTransform()
        startTransform.setIdentity()

        let mass: Float = 1
        let localInertia = colShape.calculateLocalInertia(mass: mass)

        startTransform.origin = float3(140, 1443, 100) * q2b

        let colMotionState = BulletMotionState(transform: startTransform)

        let colBody = BulletRigidBody(mass: mass,
                                      motionState: colMotionState,
                                      collisionShape: colShape,
                                      localInertia: localInertia)

        world.add(rigidBody: colBody)

        pinkCubeMotion = colMotionState
        
        pinkCubeTransform.scale = float3(30, 30, 30)
        Debug.shared.addCube(transform: pinkCubeTransform, color: float4(1, 0, 0, 1))
    }
    
    private func createRamp()
    {
        let position = float3(0, 1374, 4)
        let scale = float3(340, 96, 8)
        
        let shape = BulletBoxShape(halfExtents: scale * 0.5 * q2b)
        
        let startTransform = BulletTransform()
        startTransform.setIdentity()
        
        startTransform.origin = position * q2b
        
        let motionState = BulletMotionState(transform: startTransform)
        
        let mass: Float = 5
        let localInertia = shape.calculateLocalInertia(mass: mass)
        
        let body = BulletRigidBody(mass: mass,
                                   motionState: motionState,
                                   collisionShape: shape,
                                   localInertia: localInertia)
        
        world.add(rigidBody: body)
        
        let transform = Transform()
        transform.position = position
        transform.scale = scale
        
        Debug.shared.addCube(transform: transform, color: float4(1, 0, 1, 1))
        
        rampTransform = transform
        rampMotion = motionState
        
        let hinge = BulletHingeConstraint(nodeA: body, pivotA: .zero, axisA: .y_axis)
        world.add(hinge, disableCollisionsBetweenLinkedBodies: true)
    }
}
