//
//  HierarchyPanel.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 08.09.2023.
//

import ImGui

final class HierarchyPanel
{
    let name = "World"
    
    func draw()
    {
        ImGuiBegin(name, nil, 0)
        
        drawPlayerStart()
        
        for (i, brush) in BrushScene.current.brushes.enumerated()
        {
            drawBrush(brush, index: i)
        }
        
        ImGuiEnd()
    }
    
    private func drawBrush(_ brush: EditableObject, index: Int)
    {
        ImGuiPushStyleVar(Im(ImGuiStyleVar_ItemSpacing), ImVec2(8, 6))
        ImGuiPushStyleVar(Im(ImGuiStyleVar_FramePadding), ImVec2(1, 3))

        var flags = Im(ImGuiTreeNodeFlags_Leaf) | Im(ImGuiTreeNodeFlags_Bullet)

        flags |= (brush.isSelected) ? Im(ImGuiTreeNodeFlags_Selected) : 0

        let opened = ImGuiTreeNodeEx("Brush #\(index)", flags)

        if ImGuiIsItemClicked(Im(ImGuiMouseButton_Left))
        {
            if brush.isSelected
            {
                brush.isSelected = false
            }
            else
            {
                for j in BrushScene.current.brushes.indices
                {
                    BrushScene.current.brushes[j].isSelected = j == index
                }
            }
        }

        if opened
        {
            ImGuiTreePop()
        }

        ImGuiPopStyleVar(2)  // ItemSpacing & FramePadding
    }
    
    private func drawPlayerStart()
    {
        let entity = BrushScene.current.infoPlayerStart
        
        ImGuiPushStyleVar(Im(ImGuiStyleVar_ItemSpacing), ImVec2(8, 6))
        ImGuiPushStyleVar(Im(ImGuiStyleVar_FramePadding), ImVec2(1, 3))

        var flags = Im(ImGuiTreeNodeFlags_Leaf) | Im(ImGuiTreeNodeFlags_Bullet)

        flags |= (entity.isSelected) ? Im(ImGuiTreeNodeFlags_Selected) : 0

        let opened = ImGuiTreeNodeEx("Info Player Start", flags)

        if ImGuiIsItemClicked(Im(ImGuiMouseButton_Left))
        {
            entity.isSelected.toggle()
        }

        if opened
        {
            ImGuiTreePop()
        }

        ImGuiPopStyleVar(2)  // ItemSpacing & FramePadding
    }
}
