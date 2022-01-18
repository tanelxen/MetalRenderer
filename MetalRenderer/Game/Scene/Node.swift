//
//  Node.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

class Node
{
    private let name: String
    private let id: String
    
    var transform = Transform()
    
    //AABB
    var minBounds: float3 = .one
    var maxBounds: float3 = .zero
    var center: float3 = float3(0.5, 0.5, 0.5)
    
    private var worldAABBVertices: [float3] = []
    
    private var worldCenter: float3 = float3(0.5, 0.5, 0.5)
    private var worldMinBounds: float3 = .one
    private var worldMaxBounds: float3 = .one
    private var worldSphereRadius: Float = 1
    
    var children: [Node] = []
    
    var frustumTest = true
    var isVisible = true
    
    init(name: String = "Node")
    {
        self.name = name
        self.id = UUID().uuidString
    }
    
    func addChild(_ child: Node)
    {
        children.append(child)
    }
    
    /// Override this function instead of the update function
    func doUpdate() { }
    
    func updateVisibility()
    {
        isVisible = visibilityBoundingSphere()
    }
    
    func updateTransform()
    {
        transform.updateModelMatrix()
        
        worldMinBounds = transform.matrix * minBounds
        worldMaxBounds = transform.matrix * maxBounds
        worldSphereRadius = simd_length(worldMaxBounds - worldMinBounds) * 0.5
        worldCenter = transform.matrix * center
        
        updateAABB()
        
        for child in children
        {
            child.transform.parent = transform.matrix
            child.updateTransform()
        }
    }
    
    private func updateAABB()
    {
        worldAABBVertices = [
            float3(worldMinBounds.x, worldMinBounds.y, worldMinBounds.z),
            float3(worldMaxBounds.x, worldMinBounds.y, worldMinBounds.z),
            float3(worldMinBounds.x, worldMaxBounds.y, worldMinBounds.z),
            float3(worldMaxBounds.x, worldMaxBounds.y, worldMinBounds.z),
            float3(worldMinBounds.x, worldMinBounds.y, worldMaxBounds.z),
            float3(worldMaxBounds.x, worldMinBounds.y, worldMaxBounds.z),
            float3(worldMinBounds.x, worldMaxBounds.y, worldMaxBounds.z),
            float3(worldMaxBounds.x, worldMaxBounds.y, worldMaxBounds.z),
        ]
    }
    
    func update()
    {
//        transform.updateModelMatrix()
        updateVisibility()
        
        doUpdate()
        
        for child in children
        {
//            child.transform.parent = transform.matrix
            child.update()
        }
    }
    
    func render(with encoder: MTLRenderCommandEncoder?)
    {
        if frustumTest && !isVisible
        {
            return
        }
        
        encoder?.pushDebugGroup("Rendering \(name)")
        
        (self as? Renderable)?.doRender(with: encoder)
        
        for child in children
        {
            child.render(with: encoder)
        }
        
        encoder?.popDebugGroup()
    }
    
    private func visibilityAABB() -> Bool
    {
        return DebugCamera.shared.boxInFrustum(mins: worldMinBounds, maxs: worldMaxBounds)
//        return DebugCamera.shared.meshInFrustum(vertices: worldAABBVertices)
    }
    
    private func visibilityBoundingSphere() -> Bool
    {
        return DebugCamera.shared.sphereInFrustum(worldCenter, radius: worldSphereRadius)
    }
}
