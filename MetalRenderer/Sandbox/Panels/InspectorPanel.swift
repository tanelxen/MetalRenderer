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
        
        guard let brush = BrushScene.current.selected else { return }
        
        ImGuiCheckbox("Is Room", &brush.isRoom)
    }
}
