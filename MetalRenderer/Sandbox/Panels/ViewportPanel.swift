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
        Q3MapScene.current?.isPlaying ?? false
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
            if let transform = guizmoTransform
            {
//                renderGizmo(for: transform)
                dragFace(at: transform)
            }
            
            drawPlayPauseControl()
            isHovered = isHovered && !ImGuiIsItemHovered(ImGuiFlag_None)
        }
        
        ImGuiEnd()
    }
    
    private func dragFace(at transform: Transform)
    {
        guard isHovered else { return }
        
        guard Mouse.IsMouseButtonPressed(.left)
        else {
            dragOrigin = nil
            objectInitialPos = nil
            return
        }
        
        guard let start = dragOrigin, let origin = objectInitialPos
        else {
            dragOrigin = viewport.mousePositionInWorld().origin
            objectInitialPos = transform.position
            return
        }
        
        guard let normal = BrushScene.current.selected?.selectedFaceNormal
        else {
            return
        }
        
        let axis = float3(abs(normal.x), abs(normal.y), abs(normal.z))
        
        let end = viewport.mousePositionInWorld().origin
        
        var value = dot(axis, end - start) * 1000
        
        let gridSize: Float = 16
        value = round(value / gridSize) * gridSize
        
        transform.position = origin + value
        
        BrushScene.current.selected?.selectedFaceTransform = transform
    }
    
    private func startPlaying()
    {
        guard let scene = Q3MapScene.current else { return }
        
        scene.startPlaying(in: viewport)
        
        NSCursor.hide()
        CGAssociateMouseAndMouseCursorPosition(0)
    }
    
    private func stopPlaying()
    {
        Q3MapScene.current.stopPlaying()
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
        var snapValues: float3 = float3(repeating: 8)
        
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
        
//        if ImGuizmoIsUsing()
//        {
//            transform.position = modelMatrix.columns.3.xyz
//            BrushScene.current.brush.selectedFaceTransform = transform
//        }
    }
    
    private func selectObject()
    {
        guard isHovered else { return }
        guard !ImGuizmoIsUsing() else { return }
        
        guard let brush = BrushScene.current.selected else { return }
        
        let ray = viewport.mousePositionInWorld()
        
//        let end = ray.origin + ray.direction * 1024
//        Debug.shared.addLine(start: ray.origin, end: end, color: float4(0, 1, 0, 1))
        
        brush.selectFace(by: ray)
        
//        if let pos = brush.selectedFaceTransform?.position
//        {
//            print(pos)
//        }
        
        guizmoTransform = brush.selectedFaceTransform
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
