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
    
    let brush = WorldBrush(minBounds: .zero, maxBounds: float3(64, 64, 64))
    
    var brushes: [WorldBrush] = []
    
    lazy var grid: GridHelper = {
        let helper = GridHelper()
        helper.scene = self
        return helper
    }()
    
    init()
    {
//        brush.transform.position = float3(144, 1440, 128)
        
        BrushScene.current = self
    }
    
    func addBrush(position: float3, size: float3)
    {
        let start = position
        let end = position + size
        
        let mins = min(start, end)
        let maxs = max(start, end)
        
        let brush = WorldBrush(minBounds: mins, maxBounds: maxs)
        
        brushes.append(brush)
    }
    
    func update()
    {
        grid.update()
    }
    
    func render(with encoder: MTLRenderCommandEncoder?)
    {
        grid.render(with: encoder)
        brush.render(with: encoder)
        
        for brush in brushes
        {
            brush.render(with: encoder)
        }
    }
}
