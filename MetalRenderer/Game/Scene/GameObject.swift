//
//  GameObject.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

class GameObject: Node
{
    private var mesh: Mesh
    
    init(name: String = "GameObject", mesh: Mesh)
    {
        self.mesh = mesh
        super.init(name: name)
    }

    override func doUpdate()
    {
        mesh.transform = transform.matrix
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
