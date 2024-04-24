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
    
    lazy var gridQuad = QuadShape(mins: float3(-4096, -4096, 0), maxs: float3(4096, 4096, 0))
    
    let brush = WorldBrush(minBounds: .zero, maxBounds: float3(64, 64, 64))
    
    var brushes: [WorldBrush] = []
    
    lazy var grid: GridHelper = {
        let helper = GridHelper()
        helper.scene = self
        return helper
    }()
    
    init()
    {
        brush.isSelected = true
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
    
    func render(with encoder: MTLRenderCommandEncoder, to renderer: ForwardRenderer)
    {
        renderer.apply(tehnique: .grid, to: encoder)
        var modelConstants = ModelConstants()
        encoder.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        gridQuad.render(with: encoder)
        
        renderer.apply(tehnique: .basic, to: encoder)
        grid.render(with: encoder)
        
        brush.render(with: encoder, to: renderer)
        
        for brush in brushes
        {
            brush.render(with: encoder, to: renderer)
        }
    }
}
