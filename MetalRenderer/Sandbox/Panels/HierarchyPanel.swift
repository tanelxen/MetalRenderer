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
    
    private var selectedBSPNode: BSPNode?
    private var selectedBSPPlane: BSPNode.Plane?
    
    private var selectedKdNode: KdNode?
    private var selectedKdPlane: KdNode.Plane?
    
    private var selectedNode: OctreeNode?
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
//            drawKdTree(scene.kdTree)
//            drawBspTree(scene.bspTree)
            drawOctree(scene.octree)
            ImGuiTreePop()
        }

        ImGuiPopStyleVar(2)  // ItemSpacing & FramePadding
    }
    
    private func drawBrushesList(_ brushes: [Brush])
    {
        ImGuiPushStyleVar(Im(ImGuiStyleVar_ItemSpacing), ImVec2(8, 6))
        ImGuiPushStyleVar(Im(ImGuiStyleVar_FramePadding), ImVec2(1, 3))

        let flags: ImGuiTreeNodeFlags = Im(ImGuiTreeNodeFlags_SpanAvailWidth) | Im(ImGuiTreeNodeFlags_OpenOnArrow) | Im(ImGuiTreeNodeFlags_OpenOnDoubleClick)

//        flags |= (entity === selectedEntity) ? Im(ImGuiTreeNodeFlags_Selected) : 0
        
        if ImGuiTreeNodeEx("Brushes", flags)
        {
            for brush in brushes
            {
                drawBrush(brush)
            }
            
            ImGuiTreePop()
        }

        ImGuiPopStyleVar(2)  // ItemSpacing & FramePadding
    }
    
    private func drawKdTree(_ tree: KdTree)
    {
        ImGuiPushStyleVar(Im(ImGuiStyleVar_ItemSpacing), ImVec2(8, 6))
        ImGuiPushStyleVar(Im(ImGuiStyleVar_FramePadding), ImVec2(1, 3))

        let flags: ImGuiTreeNodeFlags = Im(ImGuiTreeNodeFlags_SpanAvailWidth) | Im(ImGuiTreeNodeFlags_OpenOnArrow) | Im(ImGuiTreeNodeFlags_OpenOnDoubleClick)

//        flags |= (entity === selectedEntity) ? Im(ImGuiTreeNodeFlags_Selected) : 0
        
        if ImGuiTreeNodeEx("KD-Tree", flags)
        {
            if let root = tree.root
            {
                drawNode(root, named: "\(FAIcon.shapes) root")
            }
            
            ImGuiTreePop()
        }

        ImGuiPopStyleVar(2)  // ItemSpacing & FramePadding
    }
    
    private func drawNode(_ node: KdNode, named: String)
    {
        ImGuiPushStyleVar(Im(ImGuiStyleVar_ItemSpacing), ImVec2(8, 6))
        ImGuiPushStyleVar(Im(ImGuiStyleVar_FramePadding), ImVec2(1, 3))

        var flags: ImGuiTreeNodeFlags = Im(ImGuiTreeNodeFlags_SpanAvailWidth) | Im(ImGuiTreeNodeFlags_OpenOnArrow)
        flags |= (node === selectedKdNode) ? Im(ImGuiTreeNodeFlags_Selected) : 0
        
        let opened = ImGuiTreeNodeEx(named, flags)
        
        if ImGuiIsItemClicked(Im(ImGuiMouseButton_Left))
        {
            if selectedKdNode === node
            {
                selectedKdNode = nil
            }
            else
            {
                selectedKdNode = node
            }
        }
        
        if opened
        {
            if let plane = node.plane
            {
                drawPlane(plane)
            }
            
            if let left = node.left
            {
                drawNode(left, named: "\(FAIcon.shareAlt) left")
            }
            
            if let right = node.right
            {
                drawNode(right, named: "\(FAIcon.shareAlt) right")
            }
            
            for brush in node.items
            {
                drawBrush(brush)
            }
            
            ImGuiTreePop()
        }

        ImGuiPopStyleVar(2)  // ItemSpacing & FramePadding
    }
    
    private func drawBspTree(_ collision: BSPTree)
    {
        ImGuiPushStyleVar(Im(ImGuiStyleVar_ItemSpacing), ImVec2(8, 6))
        ImGuiPushStyleVar(Im(ImGuiStyleVar_FramePadding), ImVec2(1, 3))

        let flags: ImGuiTreeNodeFlags = Im(ImGuiTreeNodeFlags_SpanAvailWidth) | Im(ImGuiTreeNodeFlags_OpenOnArrow) | Im(ImGuiTreeNodeFlags_OpenOnDoubleClick)

//        flags |= (entity === selectedEntity) ? Im(ImGuiTreeNodeFlags_Selected) : 0
        
        if ImGuiTreeNodeEx("BSP", flags)
        {
            if let root = collision.root
            {
                drawNode(root, named: "\(FAIcon.shapes) root")
            }
            
            ImGuiTreePop()
        }

        ImGuiPopStyleVar(2)  // ItemSpacing & FramePadding
    }
    
    private func drawNode(_ node: BSPNode, named: String)
    {
        ImGuiPushStyleVar(Im(ImGuiStyleVar_ItemSpacing), ImVec2(8, 6))
        ImGuiPushStyleVar(Im(ImGuiStyleVar_FramePadding), ImVec2(1, 3))

        var flags: ImGuiTreeNodeFlags = Im(ImGuiTreeNodeFlags_SpanAvailWidth) | Im(ImGuiTreeNodeFlags_OpenOnArrow)
        flags |= (node === selectedBSPNode) ? Im(ImGuiTreeNodeFlags_Selected) : 0
        
        let opened = ImGuiTreeNodeEx(named, flags)
        
        if ImGuiIsItemClicked(Im(ImGuiMouseButton_Left))
        {
            if selectedBSPNode === node
            {
                selectedBSPNode = nil
            }
            else
            {
                selectedBSPNode = node
            }
        }
        
        if opened
        {
            if let plane = node.plane
            {
                drawPlane(plane)
            }
            
            if let front = node.front
            {
                drawNode(front, named: "\(FAIcon.shareAlt) front")
            }
            
            if let back = node.back
            {
                drawNode(back, named: "\(FAIcon.shareAlt) back")
            }
            
            for brush in node.items
            {
                drawBrush(brush)
            }
            
            ImGuiTreePop()
        }

        ImGuiPopStyleVar(2)  // ItemSpacing & FramePadding
    }
    
    private func drawOctree(_ collision: Octree)
    {
        ImGuiPushStyleVar(Im(ImGuiStyleVar_ItemSpacing), ImVec2(8, 6))
        ImGuiPushStyleVar(Im(ImGuiStyleVar_FramePadding), ImVec2(1, 3))

        let flags: ImGuiTreeNodeFlags = Im(ImGuiTreeNodeFlags_SpanAvailWidth) | Im(ImGuiTreeNodeFlags_OpenOnArrow) | Im(ImGuiTreeNodeFlags_OpenOnDoubleClick)

//        flags |= (entity === selectedEntity) ? Im(ImGuiTreeNodeFlags_Selected) : 0
        
        if ImGuiTreeNodeEx("Octree", flags)
        {
            if let root = collision.root
            {
                drawNode(root, named: "root")
            }
            
            ImGuiTreePop()
        }

        ImGuiPopStyleVar(2)  // ItemSpacing & FramePadding
    }
    
    private func drawNode(_ node: OctreeNode, named: String)
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
            if let child = node.frontLeftTop
            {
                drawNode(child, named: "frontLeftTop")
            }
            
            if let child = node.frontLeftBottom
            {
                drawNode(child, named: "frontLeftBottom")
            }
            
            if let child = node.frontRightTop
            {
                drawNode(child, named: "frontRightTop")
            }
            
            if let child = node.frontRightBottom
            {
                drawNode(child, named: "frontRightBottom")
            }
            
            if let child = node.backLeftTop
            {
                drawNode(child, named: "backLeftTop")
            }
            
            if let child = node.backLeftBottom
            {
                drawNode(child, named: "backLeftBottom")
            }
            
            if let child = node.backRightTop
            {
                drawNode(child, named: "backRightTop")
            }
            
            if let child = node.backRightBottom
            {
                drawNode(child, named: "backRightBottom")
            }
            
            for brush in node.items
            {
                drawBrush(brush)
            }
            
            ImGuiTreePop()
        }

        ImGuiPopStyleVar(2)  // ItemSpacing & FramePadding
    }
    
    private func drawPlane(_ plane: KdNode.Plane)
    {
        ImGuiPushStyleVar(Im(ImGuiStyleVar_ItemSpacing), ImVec2(8, 6))
        ImGuiPushStyleVar(Im(ImGuiStyleVar_FramePadding), ImVec2(1, 3))

        var flags: ImGuiTreeNodeFlags = Im(ImGuiTreeNodeFlags_SpanAvailWidth) | Im(ImGuiTreeNodeFlags_Leaf)
        flags |= (plane === selectedBSPPlane) ? Im(ImGuiTreeNodeFlags_Selected) : 0
        
        let axis: String = {
            switch plane.axis {
                case 0: return "X"
                case 1: return "Y"
                case 2: return "Z"
                default: return "?"
            }
        }()
        
        let opened = ImGuiTreeNodeEx("\(FAIcon.square) plane \(axis)-axis", flags)
        
        if ImGuiIsItemClicked(Im(ImGuiMouseButton_Left))
        {
            if selectedBSPPlane === plane
            {
                selectedBSPPlane = nil
            }
            else
            {
                selectedKdPlane = plane
            }
        }
        
        if opened
        {
            ImGuiTreePop()
        }

        ImGuiPopStyleVar(2)  // ItemSpacing & FramePadding
    }
    
    private func drawPlane(_ plane: BSPNode.Plane)
    {
        ImGuiPushStyleVar(Im(ImGuiStyleVar_ItemSpacing), ImVec2(8, 6))
        ImGuiPushStyleVar(Im(ImGuiStyleVar_FramePadding), ImVec2(1, 3))

        var flags: ImGuiTreeNodeFlags = Im(ImGuiTreeNodeFlags_SpanAvailWidth) | Im(ImGuiTreeNodeFlags_Leaf)
        flags |= (plane === selectedBSPPlane) ? Im(ImGuiTreeNodeFlags_Selected) : 0
        
        let opened = ImGuiTreeNodeEx("\(FAIcon.square) plane", flags)
        
        if ImGuiIsItemClicked(Im(ImGuiMouseButton_Left))
        {
            if selectedBSPPlane === plane
            {
                selectedBSPPlane = nil
            }
            else
            {
                selectedBSPPlane = plane
            }
        }
        
        if opened
        {
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
        
        let opened = ImGuiTreeNodeEx( "\(FAIcon.cube) \(brush.name)", flags)
        
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
        
        if let plane = selectedBSPPlane
        {
            let transform = Transform()
            transform.position = plane.normal * plane.distance
            
            let axis = float3.one - plane.normal
            transform.scale = axis * 4096
            
            Debug.shared.addCube(transform: transform, color: float4(0, 1, 0, 0.8), lifespan: 0)
        }
        
        if let plane = selectedKdPlane
        {
            let normal: float3 = {
                switch plane.axis {
                    case 0: return .x_axis
                    case 1: return .y_axis
                    case 2: return .z_axis
                    default: return .zero
                }
            }()
            
            let transform = Transform()
            transform.position = normal * plane.distance
            
            let axis = float3.one - normal
            transform.scale = axis * 4096
            
            Debug.shared.addCube(transform: transform, color: float4(0, 1, 0, 0.8), lifespan: 0)
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
