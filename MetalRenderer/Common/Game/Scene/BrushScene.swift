//
//  BrushScene.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 22.04.2024.
//

import Foundation
import MetalKit

final class BrushScene
{
    private (set) static var current: BrushScene!
    
    let brush = WorldBrush()
    
    lazy var grid = GridHelper()
    
    init()
    {
//        brush.transform.position = float3(144, 1440, 128)
        
        BrushScene.current = self
    }
    
    func update()
    {
        grid.update()
    }
    
    func render(with encoder: MTLRenderCommandEncoder?)
    {
        grid.render(with: encoder)
        brush.render(with: encoder)
    }
}
