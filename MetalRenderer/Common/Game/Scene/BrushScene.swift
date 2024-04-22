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
    
    init()
    {
//        brush.transform.position = float3(144, 1440, 128)
        
        BrushScene.current = self
    }
    
    func update()
    {
        
    }
    
    func render(with encoder: MTLRenderCommandEncoder?)
    {
        brush.render(with: encoder)
    }
}
