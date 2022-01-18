//
//  GameObject.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit
import RealityKit

class GameObject: Node
{
    var mesh: Mesh
    
    init(name: String = "GameObject", mesh: Mesh)
    {
        self.mesh = mesh
        super.init(name: name)
        
        self.minBounds = mesh.boundingBox.minBounds
        self.maxBounds = mesh.boundingBox.maxBounds
        
        let aabb = BoundingBox(min: minBounds, max: maxBounds)
        self.center = aabb.center
    }
}

extension GameObject: Renderable
{
    func doRender(with encoder: MTLRenderCommandEncoder?)
    {
        mesh.transform = transform.matrix
        
        mesh.doRender(with: encoder)
    }
}
