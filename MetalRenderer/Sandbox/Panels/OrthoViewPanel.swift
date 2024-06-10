//
//  TopViewPanel.swift
//  Sandbox
//
//  Created by Fedor Artemenkov on 22.05.2024.
//

import AppKit
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
        BrushScene.current?.isPlaying ?? false
    }
    
    init(viewport: Viewport)
    {
        self.viewport = viewport
        viewport.camera = camera
        viewport.viewType = .top
        
        boundsTool = BrushBoundsTool(viewport: viewport)
        blockTool = BlockTool2D(viewport: viewport)
    }
    
    private var dragOrigin: float3?
    private var objectInitialPos: float3?
    
    private var dragMode: DragMode = .none
    
    private var boundsTool: BrushBoundsTool
    private let blockTool: BlockTool2D
    
    func drawSpecial(with renderer: ForwardRenderer)
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
        if EditorLayer.current.selectionMode == .object {
            blockTool.update()
            
            boundsTool.mesh = BrushScene.current.selected as? PlainBrush
            boundsTool.update()
        }
    }
    
    private func dragObject()
    {
        guard let brush = BrushScene.current.selected else { return }
        
        guard Mouse.IsMouseButtonPressed(.left)
        else {
            dragOrigin = nil
            objectInitialPos = nil
            return
        }
        
        // Плоскость, на которую будем проецировать луч, по ней будем перемещаться
        let viewNormal = camera.transform.rotation.forward
        let plane = Plane(normal: viewNormal, distance: 0)
        
        guard let start = dragOrigin, let origin = objectInitialPos
        else {
            let ray = viewport.mousePositionInWorld()
            dragOrigin = intersection(ray: ray, plane: plane)
            objectInitialPos = brush.worldPosition
            return
        }
        
        let ray = viewport.mousePositionInWorld()
        guard let end = intersection(ray: ray, plane: plane)
        else {
            return
        }
        
        var delta = end - start
        delta = floor(delta / gridSize + 0.5) * gridSize
        
        let newPos = origin + delta
        
        brush.setWorld(position: newPos)
    }
    
    private func dragFace(at facePoint: float3, along axis: float3)
    {
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
        value = floor(value / gridSize) * gridSize
        
        let newPos = origin + axis * value
        
        BrushScene.current.selected?.setSelectedEdge(position: newPos)
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
    
    private func selectObject()
    {
        guard isHovered else { return }
        
        guard let brush = BrushScene.current.selected else { return }
        
        let ray = viewport.mousePositionInWorld()
        
//        let end = ray.origin + ray.direction * 1024
//        Debug.shared.addLine(start: ray.origin, end: end, color: float4(0, 1, 0, 1))
        
//        brush.selectEdge(by: ray)
        brush.selectFace(by: ray)
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
            
            var point = BrushScene.current.point(at: ray) ?? intersection(ray: ray, plane: plane) ?? .zero
            
            point = floor(point / gridSize + 0.5) * gridSize
            
            let entity = InfoPlayerStart()
            entity.transform.position = point + [0, 28, 0]
            
            BrushScene.current.infoPlayerStart = entity
        }
        
//        if ImGuiBeginMenu("\(FAIcon.lightbulb) Create Lights", true) {
//            if ImGuiMenuItem("Directional Light", nil, false, true) {
//                scene.createSceneLight(type: .dirLight)
//            }
//            if ImGuiMenuItem("Point Light", nil, false, true) {
//                scene.createSceneLight(type: .pointLight)
//            }
//            if ImGuiMenuItem("Spot Light", nil, false, true) {
//                scene.createSceneLight(type: .spotLight)
//            }
//            if ImGuiMenuItem("Ambient Light", nil, false, true) {
//                scene.createSceneLight(type: .ambientLight)
//            }
//            ImGuiEndMenu()
//        }
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

enum DragMode
{
    case none
    case brush
    case face
    case edge
    case vert
}

// Got from GTKRadiant matlib
private func intersect(ray: Ray, point: float3, epsilon: Float, divergence: Float) -> Bool
{
    var displacement = float3()
    var depth: Float = 0

    // calc displacement of test point from ray origin
    displacement = point - ray.origin
    
    // calc length of displacement vector along ray direction
    depth = dot(displacement, ray.direction)
    
    if depth < 0.0 {
        return false
    }
    
    // calc position of closest point on ray to test point
    displacement = ray.origin + ray.direction * depth
    
    // calc displacement of test point from closest point
    displacement = point - displacement
    
    // calc length of displacement, subtract depth-dependant epsilon
    if length(displacement) - (epsilon + ( depth * divergence )) > 0 {
        return false
    }
    
    return true
}
