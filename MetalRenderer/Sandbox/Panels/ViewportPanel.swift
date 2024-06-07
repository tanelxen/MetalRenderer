//
//  ViewportPanel.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 08.09.2023.
//

import AppKit
import ImGui
import ImGuizmo
import simd

final class ViewportPanel
{
    let name = "Viewport"
    
    private let viewport: Viewport
    private let camera = DebugCamera()
    
    private var boundsTool: BoundsTool
    private let blockTool: BlockTool3D
    
    lazy var gridQuad = QuadShape(mins: float3(-4096, 0, -4096), maxs: float3(4096, 0, 4096))
    
    lazy var utilityRenderer = MeshUtilityRenderer()
    
    private (set) var isHovered = false
    
    var isPlaying: Bool {
        BrushScene.current?.isPlaying ?? false
    }
    
    init(viewport: Viewport)
    {
        self.viewport = viewport
        viewport.camera = camera
        viewport.viewType = .perspective
        
        boundsTool = BoundsTool(viewport: viewport)
        blockTool = BlockTool3D(viewport: viewport)
    }
    
    private var gizmoType: ImGuizmoType = .translate
    
    private var dragOrigin: float3?
    private var objectInitialPos: float3?
    
    func drawSpecial(with renderer: ForwardRenderer)
    {
        var renderItem = RenderItem(technique: .grid)
        renderItem.cullMode = .none
        renderItem.allowedViews = [.perspective]
        
        renderItem.primitiveType = .triangleStrip
        renderItem.vertexBuffer = gridQuad.verticesBuffer
        renderItem.numVertices = gridQuad.numVertices
        
        renderer.add(item: renderItem)
        
        if let selected = BrushScene.current.selected as? EditableMesh
        {
            utilityRenderer.mesh = selected
            utilityRenderer.selectionMode = EditorLayer.current.selectionMode
            utilityRenderer.render(with: renderer)
        }
        
        boundsTool.draw(with: renderer)
        blockTool.draw(with: renderer)
    }
    
    func draw()
    {
        let windowFlags = Im(ImGuiWindowFlags_NoDecoration)
        
        ImGuiPushStyleVar(Im(ImGuiStyleVar_WindowPadding), ImVec2(0, 0))
        ImGuiBegin(name, nil, windowFlags)
        ImGuiPopStyleVar(1)
        
        updateViewportSize()
        
        let textureId = withUnsafePointer(to: &viewport.texture) { ptr in
            return UnsafeMutableRawPointer(mutating: ptr)
        }
        
        ImGuiImage(
            textureId,
            ImVec2(Float(viewport.width), Float(viewport.height)),
            ImVec2(x: 0, y: 0),
            ImVec2(x: 1, y: 1),
            ImVec4(x: 1, y: 1, z: 1, w: 1),
            ImVec4(x: 1, y: 1, z: 1, w: 1)
        )
        
        isHovered = ImGuiIsItemHovered(ImGuiFlag_None)
        
        if ImGuiIsItemClicked(Im(ImGuiMouseButton_Left)) && Keyboard.isKeyPressed(.shift)
        {
            selectObject()
        }
        
        if isPlaying
        {
            if ImGuiIsKeyPressedMap(Im(ImGuiKey_Escape), false)
            {
                stopPlaying()
            }
        }
        else
        {
            updateOperations()
            
            drawPlayPauseControl()
//            drawGizmoControl()
            
            isHovered = isHovered && !ImGuiIsItemHovered(ImGuiFlag_None)
        }
        
        ImGuiEnd()
        
        if isHovered
        {
            if EditorLayer.current.selectionMode == .object {
                blockTool.update()
                
                boundsTool.mesh = BrushScene.current.selected as? EditableMesh
                boundsTool.update()
            }
            
            camera.update()
        }
    }
    
    private func updateOperations()
    {
        if let entity = BrushScene.current.infoPlayerStart, entity.isSelected
        {
            let transform = Transform(position: entity.transform.position)
            
            if renderGizmo(for: transform)
            {
                entity.transform.position = transform.position
            }
            
            return
        }
        
        guard let brush = BrushScene.current.selected as? EditableMesh else { return }
        
        if EditorLayer.current.selectionMode == .face, let point = brush.selectedFacePoint
        {
            let transform = Transform(position: point)
            if renderGizmo(for: transform)
            {
                brush.setSelectedFace(position: transform.position)
            }
            
            if ImGuiIsKeyPressedMap(Im(ImGuiKey_E), false) && ImGuiGetIO()!.pointee.KeySuper
            {
                brush.extrudeSelectedFace(to: 16)
            }
            
            if ImGuiIsKeyPressedMap(Im(ImGuiKey_Escape), false)
            {
                brush.isSelected = true
            }
            
            if ImGuiIsKeyPressedMap(Im(ImGuiKey_Backspace), false)
            {
                brush.removeSelectedFace()
            }
        }
        else if EditorLayer.current.selectionMode == .edge, let point = brush.selectedEdgePoint
        {
            let transform = Transform(position: point)
            if renderGizmo(for: transform)
            {
                brush.setSelectedEdge(position: transform.position)
            }
            
            if ImGuiIsKeyPressedMap(Im(ImGuiKey_Escape), false)
            {
                brush.isSelected = true
            }
        }
        else if EditorLayer.current.selectionMode == .object
        {
//            if let anchor = brush.faces.first?.verts.first?.position
//            {
//                let transform = Transform(position: anchor)
//                if renderGizmo(for: transform)
//                {
//                    brush.setWorld(position: transform.position)
//                }
//            }
            
            if ImGuiIsKeyPressedMap(Im(ImGuiKey_Escape), false)
            {
                brush.isSelected = false
            }
            
            if ImGuiIsKeyPressedMap(Im(ImGuiKey_Backspace), false)
            {
                BrushScene.current.removeSelected()
            }
            
            if ImGuiIsKeyPressedMap(Im(ImGuiKey_D), false) && ImGuiGetIO()!.pointee.KeySuper
            {
                BrushScene.current.copySelected()
            }
        }
        
        if EditorLayer.current.selectionMode == .edge
        {
            let ray = viewport.mousePositionInWorld()
            
            brush.faces
                .flatMap { $0.edges }
                .forEach { $0.isHighlighted = false }
            
        faceloop: for face in brush.faces
            {
                guard intersect(ray: ray, face: face)
                else {
                    continue
                }
                
                for edge in face.edges
                {
                    let p1 = edge.vert.position
                    let p2 = edge.next.vert.position
                    
                    if closestDistance(ray: ray, lineStart: p1, lineEnd: p2) < 4
                    {
                        edge.isHighlighted = true
                        break faceloop
                    }
                }
            }
        }
    }
    
    private func dragFace(at facePoint: float3, along axis: float3)
    {
        guard isHovered else { return }
        
        guard Mouse.IsMouseButtonPressed(.left)
        else {
            dragOrigin = nil
            objectInitialPos = nil
            return
        }
        
        // Плоскость, на которую будем проецировать луч, по ней будем перемещаться
        let viewNormal = camera.transform.rotation.forward
        let distance = dot(facePoint, viewNormal)
        let plane = Plane(normal: viewNormal, distance: distance)
        
        guard let start = dragOrigin, let origin = objectInitialPos
        else {
            let ray = viewport.mousePositionInWorld()
            dragOrigin = intersection(ray: ray, plane: plane)
            objectInitialPos = facePoint
            return
        }
        
        let ray = viewport.mousePositionInWorld()
        guard let end = intersection(ray: ray, plane: plane)
        else {
            return
        }
        
        var value = dot(axis, end - start)
        
        let gridSize: Float = 8
        value = floor(value / gridSize) * gridSize
        
        let newPos = origin + axis * value
        
        BrushScene.current.selected?.setSelectedFace(position: newPos)
    }
    
    private func dragEdge(at edgePoint: float3, along axis: float3)
    {
        guard isHovered else { return }
        
        guard Mouse.IsMouseButtonPressed(.left)
        else {
            dragOrigin = nil
            objectInitialPos = nil
            return
        }
        
        // Плоскость, на которую будем проецировать луч, по ней будем перемещаться
        let viewNormal = camera.transform.rotation.forward
        let distance = dot(edgePoint, viewNormal)
        let plane = Plane(normal: viewNormal, distance: distance)
        
        guard let start = dragOrigin, let origin = objectInitialPos
        else {
            let ray = viewport.mousePositionInWorld()
            dragOrigin = intersection(ray: ray, plane: plane)
            objectInitialPos = edgePoint
            return
        }
        
        let ray = viewport.mousePositionInWorld()
        guard let end = intersection(ray: ray, plane: plane)
        else {
            return
        }
        
        var value = dot(axis, end - start)
        
        let gridSize: Float = 16
        value = floor(value / gridSize) * gridSize
        
        let newPos = origin + axis * value
        
        BrushScene.current.selected?.setSelectedEdge(position: newPos)
    }
    
    private func startPlaying()
    {
        guard let scene = BrushScene.current else { return }
        
        scene.startPlaying(in: viewport)
        
        NSCursor.hide()
        CGAssociateMouseAndMouseCursorPosition(0)
    }
    
    private func stopPlaying()
    {
        BrushScene.current.stopPlaying()
        viewport.camera = camera
        
        NSCursor.unhide()
        CGAssociateMouseAndMouseCursorPosition(1)
    }
    
    private func updateViewportSize()
    {
        var viewportMinRegion = ImVec2()
        var viewportMaxRegion = ImVec2()
        var viewportOffset = ImVec2()
        
        ImGuiGetWindowContentRegionMin(&viewportMinRegion)
        ImGuiGetWindowContentRegionMax(&viewportMaxRegion)
        ImGuiGetWindowPos(&viewportOffset)
        
        let min: SIMD2<Float> = [viewportMinRegion.x + viewportOffset.x,
                                 viewportMinRegion.y + viewportOffset.y]
        
        let max: SIMD2<Float> = [viewportMaxRegion.x + viewportOffset.x,
                                 viewportMaxRegion.y + viewportOffset.y]
        
        viewport.changeBounds(min: min, max: max)
    }
    
    private func renderGizmo(for transform: Transform) -> Bool
    {
        ImGuizmoSetOrthographic(false)
        ImGuizmoSetDrawlist(nil)
        
        let boundsMin = viewport.minBounds
        let boundsMax = viewport.maxBounds
        
        ImGuizmoSetRect(
            boundsMin.x,
            boundsMin.y,
            boundsMax.x - boundsMin.x,
            boundsMax.y - boundsMin.y
        )
        
        let viewMatrix = camera.viewMatrix
        let projectionMatrix = camera.projectionMatrix
        
        transform.updateModelMatrix()
        var modelMatrix = transform.matrix
        
        // Snapping
        let snap: Bool = true //Input.isPressed(key: .shift)
        var snapValues: float3 = (gizmoType == .rotate) ? float3(repeating: 45.0) : float3(repeating: 8)
        
        withUnsafeBytes(of: viewMatrix) { (view: UnsafeRawBufferPointer) -> Void in
            withUnsafeBytes(of: projectionMatrix) { (project: UnsafeRawBufferPointer) -> Void in
                withUnsafeMutableBytes(of: &modelMatrix) { (model: UnsafeMutableRawBufferPointer) -> Void in
                    withUnsafeMutableBytes(of: &snapValues, { (values: UnsafeMutableRawBufferPointer) -> Void in
                        ImGuizmoManipulate(view.baseAddress!.assumingMemoryBound(to: Float.self),
                                           project.baseAddress!.assumingMemoryBound(to: Float.self),
                                           OPERATION(rawValue: UInt32(gizmoType.rawValue)),
                                           MODE(rawValue: UInt32(ImGuizmoMode.local.rawValue)),
                                           model.baseAddress!.assumingMemoryBound(to: Float.self),
                                           nil, (snap) ? values.baseAddress!.assumingMemoryBound(to: Float.self) : nil,
                                           nil, nil)
                    })
                }
            }
        }
        
        if ImGuizmoIsUsing()
        {
            transform.position = modelMatrix.columns.3.xyz
        }
        
        return ImGuizmoIsUsing()
    }
    
    private func selectObject()
    {
        guard let brush = BrushScene.current.selected else { return }
        
        let ray = viewport.mousePositionInWorld()
        
        switch EditorLayer.current.selectionMode
        {
            case .object:
                break
                
            case .vertex:
                break
                
            case .face:
                brush.selectFace(by: ray)
                
            case .edge:
                brush.selectEdge(by: ray)
        }
    }
    
    private func drawPlayPauseControl()
    {
        var viewportMinRegion = ImVec2()
        var viewportMaxRegion = ImVec2()
        
        ImGuiGetWindowContentRegionMin(&viewportMinRegion)
        ImGuiGetWindowContentRegionMax(&viewportMaxRegion)

        let topInset: Float = 8
        let rightInset: Float = 8
        let buttonSize = ImVec2(32, 32)

        let pos = ImVec2(
            viewportMaxRegion.x - buttonSize.x - rightInset,
            viewportMinRegion.y + topInset
        )
        
        ImGuiSetCursorPos(pos)
        drawPlayButton(buttonSize)
    }
    
    private func drawPlayButton(_ buttonSize: ImVec2 = ImVec2(0, 0))
    {
        ImGuiPushID("PlayButton")
        
        ImGuiPushStyleColor(Im(ImGuiCol_Button), ImGuiTheme.disabled)
        ImGuiPushStyleColor(Im(ImGuiCol_ButtonHovered), ImGuiTheme.hovered)
        ImGuiPushStyleColor(Im(ImGuiCol_ButtonActive), ImGuiTheme.disabled)
        
        ImGuiButton("\(FAIcon.play)", buttonSize)
        
        if ImGuiIsItemClicked(Im(ImGuiMouseButton_Left))
        {
            startPlaying()
        }
        
        ImGuiPopStyleColor(3)
        
        ImGuiPopID()
    }
    
    private func drawGizmoControl()
    {
        let windowFlags: ImGuiWindowFlags = Im(ImGuiWindowFlags_NoDecoration) | Im(ImGuiWindowFlags_NoDocking)
            | Im(ImGuiWindowFlags_AlwaysAutoResize) | Im(ImGuiWindowFlags_NoSavedSettings)
            | Im(ImGuiWindowFlags_NoFocusOnAppearing) | Im(ImGuiWindowFlags_NoNav)
        
        ImGuiPushStyleVar(Im(ImGuiStyleVar_WindowBorderSize), 0.0)
        
        var viewportPos: ImVec2 = ImVec2(0, 0)
        ImGuiGetWindowPos(&viewportPos)
        
        let tabBarHeight: Float = 23
        
        var viewportWindowSize: ImVec2 = ImVec2(0, 0)
        ImGuiGetWindowSize(&viewportWindowSize)
        
        let paddingSize: Float = 8.0
        
        ImGuiSetNextWindowPos(ImVec2(viewportPos.x + paddingSize, viewportPos.y + tabBarHeight + paddingSize), 0, ImVec2(0, 0))
        
//        ImGuiBegin("GizmoControl", nil, windowFlags)
//        drawGizmoTypeButton("\(FAIcon.handPaper)", .none)
//        ImGuiSpacing()
//        drawGizmoTypeButton("\(FAIcon.arrowsAlt)", .translate)
//        ImGuiSpacing()
//        drawGizmoTypeButton("\(FAIcon.syncAlt)", .rotate)
//        ImGuiSpacing()
//        drawGizmoTypeButton("\(FAIcon.expand)", .scale)
        
        if ImGuiBegin("SelectionMode", nil, windowFlags)
        {
            drawSelectionModeButton("Object", .object)
            ImGuiSpacing()
            drawSelectionModeButton("Face", .face)
            ImGuiSpacing()
            drawSelectionModeButton("Edge", .edge)
            
            ImGuiEnd()
        }
        
        ImGuiPopStyleVar(1)
    }
    
    private func drawGizmoTypeButton(_ icon: String, _ type: ImGuizmoType)
    {
        ImGuiPushID("GizmoTypeButton\(icon)")
        
        let col = gizmoType == type ? ImGuiTheme.enabled : ImGuiTheme.disabled
        
        ImGuiPushStyleColor(Im(ImGuiCol_Button), col)
        ImGuiPushStyleColor(Im(ImGuiCol_ButtonHovered), col)
        ImGuiPushStyleColor(Im(ImGuiCol_ButtonActive), col)
        ImGuiButton(icon, ImVec2(0, 0))
        
        if ImGuiIsItemClicked(Im(ImGuiMouseButton_Left)) {
            gizmoType = type
        }
        
        ImGuiPopStyleColor(3)
        
        ImGuiPopID()
    }
    
    private func drawSelectionModeButton(_ icon: String, _ mode: SelectionMode)
    {
//        ImGuiPushID("SelectiomModeButton\(icon)")
//
//        let col = selectionMode == mode ? ImGuiTheme.enabled : ImGuiTheme.disabled
//
//        ImGuiPushStyleColor(Im(ImGuiCol_Button), col)
//        ImGuiPushStyleColor(Im(ImGuiCol_ButtonHovered), col)
//        ImGuiPushStyleColor(Im(ImGuiCol_ButtonActive), col)
//        ImGuiButton(icon, ImVec2(0, 0))
//
//        if ImGuiIsItemClicked(Im(ImGuiMouseButton_Left)) {
//            selectionMode = mode
//        }
//
//        ImGuiPopStyleColor(3)
//
//        ImGuiPopID()
    }
}

enum SelectionMode: String
{
    case object
    case vertex
    case face
    case edge
}

private enum ImGuizmoType: Int
{
    case none      = -1
    case translate = 0
    case rotate    = 1
    case scale     = 2
    case bounds    = 3
}

private enum ImGuizmoMode: Int
{
    case local = 0
    case world = 1
}
