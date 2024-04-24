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
            let mins = brush.mins
            let maxs = brush.maxs
            
            ImGuiTextV("min: X(\(mins.x)) Y(\(mins.y)) Z(\(mins.z))")
            ImGuiTextV("max: X(\(maxs.x)) Y(\(maxs.y)) Z(\(maxs.z))")
        }
        
        ImGuiEnd()
    }
}
