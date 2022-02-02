//
//  Node.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

class Node
{
    let name: String
    let id: String
    
    var transform = Transform()
    
    //AABB
    var minBounds: float3 = .one
    var maxBounds: float3 = .zero
    var center: float3 = float3(0.5, 0.5, 0.5)
    
    private var worldAABBVertices: [float3] = []
    
    var worldCenter: float3 = float3(0.5, 0.5, 0.5)
    private var worldMinBounds: float3 = .one
    private var worldMaxBounds: float3 = .one
    private var worldSphereRadius: Float = 1
    
    private var aabb: AABB?
    
    var children: [Node] = []
    
    var frustumTest = false
    var isVisible = false
    
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
        
        aabb = AABB(min: minBounds, max: maxBounds)
        aabb?.transform = transform
    }
    
    private func updateAABB()
    {
        worldAABBVertices = [
            float3(worldMinBounds.x, worldMaxBounds.y, worldMaxBounds.z), //frontLeftTop
            float3(worldMinBounds.x, worldMinBounds.y, worldMaxBounds.z), //frontLeftBottom
            float3(worldMaxBounds.x, worldMaxBounds.y, worldMaxBounds.z), //frontRightTop
            float3(worldMaxBounds.x, worldMinBounds.y, worldMaxBounds.z), //frontRightBottom
            float3(worldMinBounds.x, worldMaxBounds.y, worldMinBounds.z), //backLeftTop
            float3(worldMinBounds.x, worldMinBounds.y, worldMinBounds.z), //backLeftBottom
            float3(worldMaxBounds.x, worldMaxBounds.y, worldMinBounds.z), //backRightTop
            float3(worldMaxBounds.x, worldMinBounds.y, worldMinBounds.z), //backRightBottom
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
    
    func render(with encoder: MTLRenderCommandEncoder?, useMaterials: Bool)
    {
        if frustumTest && !isVisible
        {
            return
        }
        
        encoder?.pushDebugGroup("Rendering \(name)")
        
        (self as? Renderable)?.doRender(with: encoder, useMaterials: useMaterials)
        
        for child in children
        {
            child.render(with: encoder, useMaterials: useMaterials)
        }
        
        encoder?.popDebugGroup()
    }
    
    func renderBoundingBox(with encoder: MTLRenderCommandEncoder?)
    {
        aabb?.render(with: encoder)
    }
    
    private func visibilityAABB() -> Bool
    {
        return DebugCamera.shared.boxInFrustum(mins: worldMinBounds, maxs: worldMaxBounds)
//        return DebugCamera.shared.meshInFrustum(vertices: worldAABBVertices)
        
//        return DebugCamera.shared.aabbInFrustum(min: worldMinBounds, max: worldMaxBounds)
    }
    
    private func visibilityBoundingSphere() -> Bool
    {
        return DebugCamera.shared.sphereInFrustum(worldCenter, radius: worldSphereRadius)
    }
}
