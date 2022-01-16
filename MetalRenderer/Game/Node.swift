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
    
    let transform = Transform()
    
    var children: [Node] = []
    
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
    
    func update()
    {
        doUpdate()
        
        for child in children
        {
            child.transform.parent = transform.matrix
            child.update()
        }
    }
    
    func render(with encoder: MTLRenderCommandEncoder?)
    {
        encoder?.pushDebugGroup("Rendering \(name)")
        
        (self as? Renderable)?.doRender(with: encoder)
        
        for child in children
        {
            child.render(with: encoder)
        }
        
        encoder?.popDebugGroup()
    }
}
