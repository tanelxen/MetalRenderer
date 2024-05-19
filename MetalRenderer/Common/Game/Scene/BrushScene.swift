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
    
    lazy var gridQuad = QuadShape(mins: float3(-4096, 0, -4096), maxs: float3(4096, 0, 4096))
    
    var brushes: [EditableMesh] = []
    
    var selected: EditableMesh? {
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
    
    init()
    {
        BrushScene.current = self
        
        physicsWorld.gravity = vector3(0, -800 * q2b, 0)
    }
    
    func addBrush(position: float3, size: float3)
    {
        let brush = EditableMesh(origin: position, size: size)
        brush.isSelected = true
        
        brushes.forEach { $0.isSelected = false }
        brushes.append(brush)
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
    
    func render(with encoder: MTLRenderCommandEncoder, to renderer: ForwardRenderer)
    {
        renderer.apply(tehnique: .grid, to: encoder)
        var modelConstants = ModelConstants()
        modelConstants.modelMatrix = matrix_identity_float4x4
        encoder.setVertexBytes(&modelConstants, length: MemoryLayout<ModelConstants>.size, index: 2)
        gridQuad.render(with: encoder)
        
        renderer.apply(tehnique: .basic, to: encoder)
        grid.render(with: encoder)
        
        for brush in brushes
        {
            brush.render(with: encoder, to: renderer)
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
        for brush in brushes
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
            physicsWorld.add(rigidBody: body)
        }
    }
}
