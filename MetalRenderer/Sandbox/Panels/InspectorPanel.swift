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
        defer { ImGuiEnd() }
        
        if ImGuiButton("Clip All Brushes")
        {
            BrushScene.current.clipAllBrushes()
        }
        
        guard let brush = BrushScene.current.selected else { return }
        
        var isRoom = brush.isRoom
        
        if ImGuiCheckbox("Is Room", &isRoom)
        {
            brush.isRoom = isRoom
        }
    }
}
