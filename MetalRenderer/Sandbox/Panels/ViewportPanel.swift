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
    
    private let blockTool: BlockTool3D
    
    lazy var gridQuad = QuadShape(mins: float3(-4096, 0, -4096), maxs: float3(4096, 0, 4096))
    
    private (set) var isHovered = false
    
    var isPlaying: Bool {
        World.current?.isPlaying ?? false
    }
    
    init(viewport: Viewport)
    {
        self.viewport = viewport
        viewport.camera = camera
        viewport.viewType = .perspective
        
        blockTool = BlockTool3D(viewport: viewport)
    }
    
    private var gizmoType: ImGuizmoType = .translate
    
    func drawSpecial(with renderer: Renderer)
    {
        if !isPlaying
        {
            var renderItem = RenderItem(technique: .grid)
            renderItem.cullMode = .none
            renderItem.allowedViews = [.perspective]
            
            renderItem.primitiveType = .triangleStrip
            renderItem.vertexBuffer = gridQuad.verticesBuffer
            renderItem.numVertices = gridQuad.numVertices
            
            renderer.add(item: renderItem)
        }
        
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
            
            isHovered = isHovered && !ImGuiIsItemHovered(ImGuiFlag_None)
        }
        
        ImGuiEnd()
        
        if isHovered
        {
            switch EditorLayer.current.toolMode
            {
                case .brush:
                    blockTool.update()
                    
                case .resize:
                     break
            }
            
            camera.update()
        }
    }
    
    private func updateOperations()
    {
        if let entity = World.current.infoPlayerStart, entity.isSelected
        {
            let transform = Transform(position: entity.transform.position)
            
            if renderGizmo(for: transform)
            {
                entity.transform.position = transform.position
            }
            
            return
        }
        
        if Keyboard.isKeyPressed(.escape)
        {
            World.current.selected?.isSelected = false
        }
        
        if Keyboard.isKeyPressed(.delete)
        {
            World.current.removeSelected()
        }
    }
    
    private func startPlaying()
    {
        guard let scene = World.current else { return }
        
        scene.startPlaying(in: viewport)
        
        NSCursor.hide()
        CGAssociateMouseAndMouseCursorPosition(0)
    }
    
    private func stopPlaying()
    {
        World.current.stopPlaying()
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
