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
    
    private var selectedNode: AABBNode?
    private var selectedBrush: Brush?
    
    func draw()
    {
        ImGuiBegin(name, nil, 0)
        
        if let scene = Q3MapScene.current
        {
            drawScene(scene)
        }
        
//        if let entities = Q3MapScene.current?.map?.entities
//        {
//            for (index, entity) in entities.enumerated()
//            {
//                drawEntity(dict: entity, index: index)
//            }
//        }
        
        // Left-click on blank space: Delete game object
        if ImGuiIsMouseClicked(Im(ImGuiMouseButton_Left), false) && ImGuiIsWindowHovered(0) {
            selectedEntity = nil
        }
        
        ImGuiEnd()
        
        drawSelected()
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
    
    private func drawScene(_ scene: Q3MapScene)
    {
        ImGuiPushStyleVar(Im(ImGuiStyleVar_ItemSpacing), ImVec2(8, 6))
        ImGuiPushStyleVar(Im(ImGuiStyleVar_FramePadding), ImVec2(1, 3))

        let flags: ImGuiTreeNodeFlags = Im(ImGuiTreeNodeFlags_SpanAvailWidth) | Im(ImGuiTreeNodeFlags_OpenOnArrow) | Im(ImGuiTreeNodeFlags_OpenOnDoubleClick)

//        flags |= (entity === selectedEntity) ? Im(ImGuiTreeNodeFlags_Selected) : 0
        
        if ImGuiTreeNodeEx(scene.name, flags)
        {
            drawCollision(scene.aabbTree)
            
            ImGuiTreePop()
        }

        ImGuiPopStyleVar(2)  // ItemSpacing & FramePadding
    }
    
    private func drawCollision(_ collision: AABBTree)
    {
        ImGuiPushStyleVar(Im(ImGuiStyleVar_ItemSpacing), ImVec2(8, 6))
        ImGuiPushStyleVar(Im(ImGuiStyleVar_FramePadding), ImVec2(1, 3))

        let flags: ImGuiTreeNodeFlags = Im(ImGuiTreeNodeFlags_SpanAvailWidth) | Im(ImGuiTreeNodeFlags_OpenOnArrow) | Im(ImGuiTreeNodeFlags_OpenOnDoubleClick)

//        flags |= (entity === selectedEntity) ? Im(ImGuiTreeNodeFlags_Selected) : 0
        
        if ImGuiTreeNodeEx("AABB Tree", flags)
        {
            if let root = collision.root
            {
                drawNode(root, named: "root")
            }
            
            ImGuiTreePop()
        }

        ImGuiPopStyleVar(2)  // ItemSpacing & FramePadding
    }
    
    private func drawNode(_ node: AABBNode, named: String)
    {
        ImGuiPushStyleVar(Im(ImGuiStyleVar_ItemSpacing), ImVec2(8, 6))
        ImGuiPushStyleVar(Im(ImGuiStyleVar_FramePadding), ImVec2(1, 3))

        var flags: ImGuiTreeNodeFlags = Im(ImGuiTreeNodeFlags_SpanAvailWidth) | Im(ImGuiTreeNodeFlags_OpenOnArrow)
        flags |= (node === selectedNode) ? Im(ImGuiTreeNodeFlags_Selected) : 0
        
        let opened = ImGuiTreeNodeEx(named, flags)
        
        if ImGuiIsItemClicked(Im(ImGuiMouseButton_Left))
        {
            if selectedNode === node
            {
                selectedNode = nil
            }
            else
            {
                selectedNode = node
            }
        }
        
        if opened
        {
            if let left = node.leftChild
            {
                drawNode(left, named: "left")
            }
            
            if let right = node.rightChild
            {
                drawNode(right, named: "right")
            }
            
            if let brush = node.brush
            {
                drawBrush(brush)
            }
            
            ImGuiTreePop()
        }

        ImGuiPopStyleVar(2)  // ItemSpacing & FramePadding
    }
    
    private func drawBrush(_ brush: Brush)
    {
        ImGuiPushStyleVar(Im(ImGuiStyleVar_ItemSpacing), ImVec2(8, 6))
        ImGuiPushStyleVar(Im(ImGuiStyleVar_FramePadding), ImVec2(1, 3))

        var flags: ImGuiTreeNodeFlags = Im(ImGuiTreeNodeFlags_SpanAvailWidth) | Im(ImGuiTreeNodeFlags_Leaf)
        flags |= (brush === selectedBrush) ? Im(ImGuiTreeNodeFlags_Selected) : 0
        
        let opened = ImGuiTreeNodeEx("brush", flags)
        
        if ImGuiIsItemClicked(Im(ImGuiMouseButton_Left))
        {
            if selectedBrush === brush
            {
                selectedBrush = nil
            }
            else
            {
                selectedBrush = brush
            }
        }
        
        if opened
        {
            ImGuiTreePop()
        }

        ImGuiPopStyleVar(2)  // ItemSpacing & FramePadding
    }
    
    private func drawSelected()
    {
        if let node = selectedNode
        {
            let transform = Transform()
            transform.position = node.boundingBox.center
            transform.scale = node.boundingBox.size
            
            Debug.shared.addCube(transform: transform, color: float4(0, 0, 1, 0.5), lifespan: 0)
        }
        
        if let brush = selectedBrush
        {
            let transform = Transform()
            transform.position = (brush.minBounds + brush.maxBounds) * 0.5
            transform.scale = brush.maxBounds - brush.minBounds
            
            Debug.shared.addCube(transform: transform, color: float4(1, 0, 1, 0.8), lifespan: 0)
        }
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
