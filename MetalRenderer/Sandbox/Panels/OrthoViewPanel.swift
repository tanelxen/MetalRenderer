//
//  TopViewPanel.swift
//  Sandbox
//
//  Created by Fedor Artemenkov on 22.05.2024.
//

import ImGui
import simd

final class OrthoViewPanel
{
    let name = "Ortho"
    
    private let viewport: Viewport
    private let camera = OrthoCamera()
    
    lazy var gridQuad = QuadShape(mins: [-4096, 0, -4096], maxs: [4096, 0, 4096])
    
    private (set) var isHovered = false
    
    private let gridSize: Float = 8
    
    var isPlaying: Bool {
        World.current?.isPlaying ?? false
    }
    
    init(viewport: Viewport)
    {
        self.viewport = viewport
        viewport.camera = camera
        viewport.viewType = .top
        
        boundsTool = BoundsTool(viewport: viewport)
        blockTool = BlockTool2D(viewport: viewport)
    }
    
    private var boundsTool: BoundsTool
    private let blockTool: BlockTool2D
    
    func drawSpecial(with renderer: Renderer)
    {
        var renderItem = RenderItem(technique: .grid)
        renderItem.cullMode = .none
        renderItem.allowedViews = [viewport.viewType]
        
        renderItem.primitiveType = .triangleStrip
        
        renderItem.vertexBuffer = gridQuad.verticesBuffer
        renderItem.numVertices = gridQuad.numVertices
        
        switch viewport.viewType
        {
            case .top, .perspective:
                renderItem.transform.rotation = Rotator(pitch: 0, yaw: 0, roll: 0)
                
            case .right:
                renderItem.transform.rotation = Rotator(pitch: 90, yaw: -90, roll: 0)
                
            case .back:
                renderItem.transform.rotation = Rotator(pitch: 90, yaw: 0, roll: 0)
        }
        
        renderer.add(item: renderItem)
        
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
        
        // Right-click: Pop-up for creation
        if ImGuiBeginPopupContextWindow(nil, Im(ImGuiPopupFlags_MouseButtonRight))
        {
            let ray = viewport.mousePositionInWorld()
            
            drawEntityCreationMenu(with: ray)
            ImGuiEndPopup()
        }
        
        drawControls()
        
        isHovered = isHovered && !ImGuiIsItemHovered(ImGuiFlag_None)
        
        ImGuiEnd()
        
        if isHovered
        {
            update()
            camera.update()
        }
    }
    
    private func update()
    {
        switch EditorLayer.current.toolMode
        {
            case .brush:
                blockTool.update()
                
            case .resize:
                boundsTool.mesh = World.current.selected
                boundsTool.update()
        }
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
    
    private func drawControls()
    {
        var viewportMinRegion = ImVec2()
        var viewportMaxRegion = ImVec2()
        
        ImGuiGetWindowContentRegionMin(&viewportMinRegion)
        ImGuiGetWindowContentRegionMax(&viewportMaxRegion)

        let topInset: Float = 8
        let leftInset: Float = 8

        let pos = ImVec2(
            viewportMinRegion.x + leftInset,
            viewportMinRegion.y + topInset
        )
        
        ImGuiSetCursorPos(pos)
        
        ImGuiPushItemWidth(70)
        if ImGuiBeginCombo("##ViewType", viewport.viewType.name, Im(ImGuiComboFlags_None))
        {
            for item in [ViewType.top, ViewType.back, ViewType.right]
            {
                let flag = Im(ImGuiSelectableFlags_SelectOnClick)
                if ImGuiSelectable(item.name, item == viewport.viewType, flag, ImVec2(0, 0))
                {
                    viewport.viewType = item
                }
            }
            
            ImGuiEndCombo()
        }
        ImGuiPopItemWidth()
    }
    
    private func drawEntityCreationMenu(with ray: Ray)
    {
        if ImGuiMenuItem("\(FAIcon.cube) Info Player Start", nil, false, true)
        {
            let viewNormal = camera.transform.rotation.forward
            let plane = Plane(normal: viewNormal, distance: 0)
            
            var point = World.current.point(at: ray) ?? intersection(ray: ray, plane: plane) ?? .zero
            
            point = floor(point / gridSize + 0.5) * gridSize
            
            let entity = InfoPlayerStart()
            entity.transform.position = point + [0, 28, 0]
            
            World.current.infoPlayerStart = entity
        }
    }
}

extension ViewType
{
    var name: String {
        switch self {
            case .top: return "Top"
            case .right: return "Right"
            case .back: return "Back"
            case .perspective: return "3D"
        }
    }
}
