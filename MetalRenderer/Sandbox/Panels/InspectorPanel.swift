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
        
        if ImGuiButton("Update CSG")
        {
            World.current.updateCSG()
        }
        
        guard let brush = World.current.selected else { return }
        
        var isRoom = brush.isRoom
        
        if ImGuiCheckbox("Is Room", &isRoom)
        {
            brush.isRoom = isRoom
        }
        
        if ImGuiBeginCombo("Texture", brush.texture, Im(ImGuiComboFlags_None))
        {
            for item in EditorLayer.current.texturesArray
            {
                ImGuiImage(
                    item.ptr,
                    ImVec2(24, 24),
                    ImVec2(0, 0),
                    ImVec2(1, 1),
                    ImVec4(1, 1, 1, 1),
                    ImVec4(1, 1, 1, 1)
                )
                
                ImGuiSameLine(0, 6)
                
                let flag = Im(ImGuiSelectableFlags_SelectOnClick)
                if ImGuiSelectable(item.name, item.name == brush.texture, flag, ImVec2(0, 0))
                {
                    brush.texture = item.name
                }
            }
            
            ImGuiEndCombo()
        }
    }
}
