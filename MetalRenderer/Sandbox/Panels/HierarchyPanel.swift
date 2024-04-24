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
    
    private var selectedEntity: EditorEntity?
    
    var selectedEntityTransform: Transform? {
        selectedEntity?.transform
    }
    
    func draw()
    {
        ImGuiBegin(name, nil, 0)
        
        for i in BrushScene.current.brushes.indices
        {
            ImGuiTextV("Brush #\(i)")
        }
        
        // Left-click on blank space: Delete game object
        if ImGuiIsMouseClicked(Im(ImGuiMouseButton_Left), false) && ImGuiIsWindowHovered(0) {
            selectedEntity = nil
        }
        
        ImGuiEnd()
    }
    
    private func drawEntity(_ entity: EditorEntity)
    {
        ImGuiPushStyleVar(Im(ImGuiStyleVar_ItemSpacing), ImVec2(8, 6))
        ImGuiPushStyleVar(Im(ImGuiStyleVar_FramePadding), ImVec2(1, 3))

        var flags: ImGuiTreeNodeFlags = Im(ImGuiTreeNodeFlags_SpanAvailWidth) | Im(ImGuiTreeNodeFlags_OpenOnArrow) | Im(ImGuiTreeNodeFlags_OpenOnDoubleClick)

        flags |= (entity === selectedEntity) ? Im(ImGuiTreeNodeFlags_Selected) : 0

        let opened = ImGuiTreeNodeEx(entity.name, flags)

        if ImGuiIsItemClicked(Im(ImGuiMouseButton_Left))
        {
            selectedEntity = entity
        }

        if opened
        {
            ImGuiTreePop()
        }

        ImGuiPopStyleVar(2)  // ItemSpacing & FramePadding
    }
    
    private func drawEntity(dict: [String: String], index: Int)
    {
        ImGuiPushStyleVar(Im(ImGuiStyleVar_ItemSpacing), ImVec2(8, 6))
        ImGuiPushStyleVar(Im(ImGuiStyleVar_FramePadding), ImVec2(1, 3))

        let flags: ImGuiTreeNodeFlags = Im(ImGuiTreeNodeFlags_SpanAvailWidth) | Im(ImGuiTreeNodeFlags_OpenOnArrow) | Im(ImGuiTreeNodeFlags_OpenOnDoubleClick)

//        flags |= (entity === selectedEntity) ? Im(ImGuiTreeNodeFlags_Selected) : 0
        
        let classname = "#\(index) " + dict["classname"]!

        if ImGuiTreeNodeEx(classname, flags)
        {
            let desc = (dict.compactMap({ (key, value) -> String in
                return "\(key): \(value)"
            }) as Array).joined(separator: "\n")
            
            ImGuiTextV(desc)
            
            ImGuiTreePop()
        }



        ImGuiPopStyleVar(2)  // ItemSpacing & FramePadding
    }
}

private class EditorEntity
{
    let name: String
    let transform: Transform
    
    init(name: String, pos: float3)
    {
        self.name = name
        self.transform = Transform()
        
        transform.position = pos
    }
}
