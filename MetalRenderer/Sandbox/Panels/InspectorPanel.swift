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
        
        ImGuiPushItemWidth(70)
        if ImGuiBeginCombo("New Brush Type", BrushScene.current.brushType.name, Im(ImGuiComboFlags_None))
        {
            for item in BrushType.allCases
            {
                let flag = Im(ImGuiSelectableFlags_SelectOnClick)
                if ImGuiSelectable(item.name, item == BrushScene.current.brushType, flag, ImVec2(0, 0))
                {
                    BrushScene.current.brushType = item
                }
            }
            
            ImGuiEndCombo()
        }
        ImGuiPopItemWidth()
        
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
        
        if !gEditorInfo.isEmpty
        {
            
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

var gEditorInfo: String = ""
