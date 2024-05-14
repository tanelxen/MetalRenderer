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
    
    lazy var box = MTKGeometry(.box, extents: [32, 32, 32])
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
    
    init()
    {
        BrushScene.current = self
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
        grid.update()
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
