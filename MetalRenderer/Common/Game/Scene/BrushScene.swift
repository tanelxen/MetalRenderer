//
//  BrushScene.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 22.04.2024.
//

import Foundation
import MetalKit
import SwiftBullet

final class BrushScene
{
    private (set) static var current: BrushScene!
    
    var brushes: [EditableObject] = []
    
    var selected: EditableObject? {
        brushes.first(where: { $0.isSelected })
    }
    
    lazy var grid: GridHelper = {
        let helper = GridHelper()
        helper.scene = self
        return helper
    }()
    
    let physicsWorld = BulletWorld()
    var player: Player?
    
    var isPlaying = false
    
    private let q2b: Float = 2.54 / 100
    private let b2q: Float = 100 / 2.54
    
    var brushType: BrushType = .mesh
    
    init()
    {
        BrushScene.current = self
        
        physicsWorld.gravity = vector3(0, -800 * q2b, 0)
    }
    
    func addBrush(position: float3, size: float3)
    {
        let brush: EditableObject
        
        switch brushType {
            case .plain:
                brush = PlainBrush(origin: position, size: size)
            case .mesh:
                brush = EditableMesh(origin: position, size: size)
        }
        
        brush.isSelected = true
        
        brushes.forEach { $0.isSelected = false }
        brushes.append(brush)
    }
    
    func copySelected()
    {
        guard let mesh = selected as? EditableMesh
        else {
            return
        }
        
        let new = EditableMesh(mesh)
        
        mesh.isSelected = false
        new.isSelected = true
        
        brushes.append(new)
    }
    
    func clipAllBrushes()
    {
        guard let cutter = selected as? PlainBrush else { return }
//        guard let plane = cutter.selectedPlane else { return }
        
        for brush in brushes
        {
            guard brush !== cutter else { continue }
            guard let plainBrush = brush as? PlainBrush else { continue }
            
            plainBrush.clip(with: cutter)
            
//            for brushB in brushes
//            {
//                guard brushA !== brushB else { continue }
//                guard let plainBrushA = brushA as? PlainBrush else { continue }
//                guard let plainBrushB = brushB as? PlainBrush else { continue }
//
//                plainBrushA.clip(with: plainBrushB)
//            }
        }
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
        if !isPlaying
        {
            grid.update()
        }
        
        if isPlaying
        {
            player?.update()
            physicsWorld.stepSimulation(timeStep: GameTime.deltaTime, maxSubSteps: 10)
        }
    }
    
    func render(with renderer: ForwardRenderer)
    {
        grid.render(with: renderer)
        
        for brush in brushes
        {
            brush.render(with: renderer)
        }
    }
}

extension BrushScene
{
    func startPlaying(in viewport: Viewport)
    {
        guard !isPlaying else { return }
        
        isPlaying = true
        
        createWorldStaticCollision()
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
        
        physicsWorld.removeAll()
        player = nil
    }
    
    private func spawnPlayer()
    {
//        guard let point = spawnPoints.first else { return }
        
        let transform = Transform()
        transform.position = float3(0, 56, 0)
        transform.rotation = .zero
        
        player = Player(scene: self)
        player?.spawn(with: transform)
    }
    
    private func createWorldStaticCollision()
    {
//        for brush in brushes
//        {
//            if brush.isRoom
//            {
//                for face in brush.faces
//                {
//                    let shape = BulletConvexHullShape()
//
//                    for point in face.verts.map({ $0.position })
//                    {
//                        shape.addPoint(point * q2b)
//                    }
//
//                    let transform = BulletTransform()
//                    transform.setIdentity()
//
//                    let motionState = BulletMotionState(transform: transform)
//                    let body = BulletRigidBody(mass: 0,
//                                               motionState: motionState,
//                                               collisionShape: shape)
//                    body.friction = 0.5
//                    physicsWorld.add(rigidBody: body)
//                }
//            }
//            else
//            {
//                let shape = BulletConvexHullShape()
//
//                for point in brush.vertices
//                {
//                    shape.addPoint(point * q2b)
//                }
//
//                let transform = BulletTransform()
//                transform.setIdentity()
//
//                let motionState = BulletMotionState(transform: transform)
//                let body = BulletRigidBody(mass: 0,
//                                           motionState: motionState,
//                                           collisionShape: shape)
//                body.friction = 0.5
//                physicsWorld.add(rigidBody: body)
//            }
//        }
    }
}

extension BrushScene
{
    func openMap(_ url: URL)
    {
        do
        {
            let data = try Data(contentsOf: url)
            
            let decoder = JSONDecoder()
            let meshes = try decoder.decode([EditableMesh].self, from: data)
            
            meshes.forEach {
                $0.recalculate()
                $0.setupRenderData()
            }
            
            brushes = meshes
        }
        catch
        {
            print(error.localizedDescription)
        }
    }
    
    func saveMap(_ url: URL)
    {
        let meshes = brushes.compactMap({ $0 as? EditableMesh })
        
        do
        {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(meshes)
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
