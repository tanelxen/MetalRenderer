//
//  InspectorPanel.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 24.04.2024.
//

import ImGui

final class InspectorPanel
{
    let name = "Properties"
    
    func draw()
    {
        ImGuiBegin(name, nil, 0)
        
        if let brush = BrushScene.current.selected
        {
            let mins = brush.origin
            let maxs = brush.size
            
            ImGuiTextV("origin: X(\(mins.x)) Y(\(mins.y)) Z(\(mins.z))")
            ImGuiTextV("dims: D(\(maxs.x)) W(\(maxs.y)) H(\(maxs.z))")
        }
        
        ImGuiEnd()
    }
}
