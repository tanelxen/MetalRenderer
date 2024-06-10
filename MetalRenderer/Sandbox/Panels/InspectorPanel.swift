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
        
        if let mesh = brush as? EditableMesh, let face = mesh.selectedFace
        {
            if ImGuiButton("Split face")
            {
                mesh.splitSelectedFace()
            }
            
            drawControlFloat2("Offset", &face.uvOffset)
            drawControlFloat2("Scale", &face.uvScale)
            face.updateUVs()
        }
        
        if let brush = brush as? PlainBrush
        {
            if ImGuiButton("Clip")
            {
                BrushScene.current.clip(brush)
            }
        }
    }
}

extension BrushType
{
    var name: String {
        switch self {
            case .plain: return "Plain"
            case .mesh: return "Mesh"
        }
    }
}
