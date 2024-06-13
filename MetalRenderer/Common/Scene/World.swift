//
//  BrushScene.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 22.04.2024.
//

import Foundation
import MetalKit
import SwiftBullet

final class World
{
    private (set) static var current: World!
    
    var brushes: [Brush] = []
    
    var infoPlayerStart: InfoPlayerStart?
    
    var selected: Brush? {
        brushes.first(where: { $0.isSelected })
    }
    
    let physicsWorld = BulletWorld()
    var player: Player?
    
    var isPlaying = false
    
    private let q2b: Float = 2.54 / 100
    private let b2q: Float = 100 / 2.54
    
    var brushType: BrushType = .plain
    
    init()
    {
        World.current = self
        
        physicsWorld.gravity = vector3(0, -800 * q2b, 0)
    }
    
    func addBrush(position: float3, size: float3)
    {
        let brush = Brush(origin: position, size: size)
        brushes.append(brush)
    }
    
    func copySelected()
    {
//        guard let mesh = selected as? EditableMesh
//        else {
//            return
//        }
//
//        let new = EditableMesh(mesh)
//
//        mesh.isSelected = false
//        new.isSelected = true
//
//        brushes.append(new)
    }
    
    func select(by ray: Ray)
    {
        // Brutforce approach
        // TODO: rewrite with AABB
        
//        var bestd: Float = .greatestFiniteMagnitude
//        var closest: EditableMesh?
//
//        for mesh in brushes.compactMap({ $0 as? EditableMesh })
//        {
//            mesh.isSelected = false
//
//            let d = intersect(ray: ray, mesh: mesh)
//
//            if d < bestd
//            {
//                closest = mesh
//                bestd = d
//            }
//        }
//
//        closest?.isSelected = true
    }
    
    /*
     Return point on nearest mesh
     */
    func point(at ray: Ray) -> float3?
    {
//        var bestd: Float = .greatestFiniteMagnitude
//        var closest: EditableMesh?
//
//        for mesh in brushes.compactMap({ $0 as? EditableMesh })
//        {
//            mesh.isSelected = false
//
//            let d = intersect(ray: ray, mesh: mesh)
//
//            if d < bestd
//            {
//                closest = mesh
//                bestd = d
//            }
//        }
//
//        if closest != nil
//        {
//            return ray.origin + ray.direction * bestd
//        }
        
        return nil
    }
    
    func removeSelected()
    {
        if let index = brushes.firstIndex(where: { $0.isSelected })
        {
            brushes.remove(at: index)
        }
    }
    
    func update()
    {
        if isPlaying
        {
            player?.update()
            physicsWorld.stepSimulation(timeStep: GameTime.deltaTime, maxSubSteps: 10)
        }
    }
    
    func render(with renderer: Renderer)
    {
        for brush in brushes
        {
            brush.render(with: renderer)
        }
        
        if !isPlaying
        {
            infoPlayerStart?.render(with: renderer)
        }
    }
    
    func updateCSG()
    {
        brushes.forEach {
            $0.updateWinding()
        }
        
        for a in brushes
        {
            for b in brushes
            {
                guard a !== b else { continue }
                a.clip(with: b)
            }
        }
    }
}

extension World
{
    func startPlaying(in viewport: Viewport)
    {
        guard !isPlaying else { return }
        
        isPlaying = true
        
        createWorldStaticCollision()
        spawnPlayer()
        
        if let camera = player?.camera
        {
            viewport.camera = camera
        }
    }
    
    func stopPlaying()
    {
        guard isPlaying else { return }
        
        isPlaying = false
        
        physicsWorld.removeAll()
        player = nil
    }
    
    private func spawnPlayer()
    {
        guard let info = infoPlayerStart else { return }
        
        let transform = Transform()
        transform.position = info.transform.position
        transform.rotation = info.transform.rotation
        
        player = Player(scene: self)
        player?.spawn(with: transform)
    }
    
    private func createWorldStaticCollision()
    {
        for brush in brushes
        {
            for poly in brush.faces.flatMap({ $0.polys })
            {
                let shape = BulletConvexHullShape()

                for point in poly.points
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
                physicsWorld.add(rigidBody: body)
            }
        }
    }
}

extension World
{
    private struct BrushSceneModel: Codable
    {
        let playerStart: InfoPlayerStartModel?
        let brushes: [Brush]
    }
    
    private struct InfoPlayerStartModel: Codable
    {
        let position: float3
        let yaw: Float
    }
    
    func openMap(_ url: URL)
    {
        do
        {
            let data = try Data(contentsOf: url)
            
            let decoder = JSONDecoder()
            let model = try decoder.decode(BrushSceneModel.self, from: data)
            
            if let playerStart = model.playerStart
            {
                let info = InfoPlayerStart()
                info.transform.position = playerStart.position
                info.transform.rotation.yaw = playerStart.yaw
                
                self.infoPlayerStart = info
            }
            
            model.brushes.forEach {
                $0.setupRenderData()
            }
            
            self.brushes = model.brushes
            
            updateCSG()
        }
        catch
        {
            print(error.localizedDescription)
        }
    }
    
    func saveMap(_ url: URL)
    {
        var playerStart: InfoPlayerStartModel?
        
        if let info = infoPlayerStart
        {
            playerStart = InfoPlayerStartModel(
                position: info.transform.position,
                yaw: info.transform.rotation.yaw
            )
        }
        
        let model = BrushSceneModel(
            playerStart: playerStart,
            brushes: brushes
        )
        
        do
        {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(model)
            try jsonData.write(to: url)
        }
        catch
        {
            print(error.localizedDescription)
        }
    }
}

enum BrushType: CaseIterable
{
    case plain
    case mesh
}