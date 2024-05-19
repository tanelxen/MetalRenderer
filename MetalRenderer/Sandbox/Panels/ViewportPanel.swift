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
    
    private (set) var isHovered = false
    
    var isPlaying: Bool {
        BrushScene.current?.isPlaying ?? false
    }
    
    init(viewport: Viewport)
    {
        self.viewport = viewport
        viewport.camera = camera
        
        BrushScene.current?.grid.viewport = viewport
        
//        Mouse.onLeftMouseDown = { [weak self] in
//            if Keyboard.isKeyPressed(.y) {
//                self?.selectObject()
//            }
//        }
    }
    
    var guizmoTransform: Transform?
    
    private var dragOrigin: float3?
    private var objectInitialPos: float3?
    
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
            if let brush = BrushScene.current.selected
            {
                if let point = brush.selectedFacePoint, let axis = brush.selectedFaceAxis
                {
                    dragFace(at: point, along: axis)

                    if ImGuiIsKeyPressedMap(Im(ImGuiKey_Escape), false)
                    {
                        brush.isSelected = true
                    }
                    
                    if ImGuiIsKeyPressedMap(Im(ImGuiKey_V), false)
                    {
                        brush.extrudeSelectedFace(to: 16)
                    }
                }
                else if let point = brush.selectedEdgePoint, let axis = brush.selectedEdgeAxis
                {
                    dragEdge(at: point, along: axis)

                    if ImGuiIsKeyPressedMap(Im(ImGuiKey_Escape), false)
                    {
                        brush.isSelected = true
                    }
                }
                else
                {
//                    renderGizmo(for: brush.transform)

                    if ImGuiIsKeyPressedMap(Im(ImGuiKey_Escape), false)
                    {
                        brush.isSelected = false
                    }
                }
                
                if ImGuiIsKeyPressedMap(Im(ImGuiKey_Backspace), false)
                {
                    BrushScene.current.removeSelected()
                }
            }
            
            drawPlayPauseControl()
            isHovered = isHovered && !ImGuiIsItemHovered(ImGuiFlag_None)
        }
        
        ImGuiEnd()
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
        
        let gridSize: Float = 16
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
    
    private func renderGizmo(for transform: Transform)
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
        var snapValues: float3 = float3(repeating: 16)
        
        let gizmoType: ImGuizmoType = .translate
        
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
    }
    
    private func selectObject()
    {
        guard isHovered else { return }
        guard !ImGuizmoIsUsing() else { return }
        
        guard let brush = BrushScene.current.selected else { return }
        
        let ray = viewport.mousePositionInWorld()
        
//        let end = ray.origin + ray.direction * 1024
//        Debug.shared.addLine(start: ray.origin, end: end, color: float4(0, 1, 0, 1))
        
//        brush.selectEdge(by: ray)
        brush.selectFace(by: ray)
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
