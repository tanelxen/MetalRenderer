//
//  AssetsPanel.swift
//  Sandbox
//
//  Created by Fedor Artemenkov on 12.09.2023.
//

import Cocoa
import ImGui

final class AssetsPanel
{
    let name = "Assets"
    
    private var names: [String] {
        
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "bsp", subdirectory: "Assets/q3/maps/")
        else {
            return []
        }
        
        return urls
            .map {
                $0.deletingPathExtension().lastPathComponent
            }
            .sorted()
    }
    
    var onLoadNewMap: ((String)->Void)?
    
    func draw()
    {
        ImGuiBegin(name, nil, 0)
        
        ImGuiPushStyleVar(Im(ImGuiStyleVar_FramePadding), ImVec2(2, 2))
        ImGuiPushStyleVar(Im(ImGuiStyleVar_ItemSpacing), ImVec2(3, 6))
        
        drawFolders()
        
        ImGuiPopStyleVar(2)
        
        ImGuiEnd()
    }
    
    private func drawFolders()
    {
        if ImGuiTreeNode("\(FAIcon.folder) Maps")
        {
            ImGuiIndent(16)
            
            for name in names
            {
                ImGuiTextV("\(FAIcon.cube) \(name)")
                
                if ImGuiIsItemHovered(0) && ImGuiIsMouseDoubleClicked(Im(ImGuiMouseButton_Left))
                {
                    onLoadNewMap?(name)
                }
            }
            
            ImGuiUnindent(16)
            ImGuiTreePop()
        }
    }
}

