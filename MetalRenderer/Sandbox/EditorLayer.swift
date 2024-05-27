//
//  EditorLayer.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 20.08.2023.
//

import ImGui
import MetalKit

final class EditorLayer
{
    private let view: MTKView
    
    private var iniPath = ""// ResourceManager.pathInPreferences(for: "editor.ini")
    
    private var viewportPanel: ViewportPanel!
    private var topViewPanel: OrthoViewPanel!
    private var hierarchyPanel: HierarchyPanel!
    private var inspectorPanel: InspectorPanel!
    private var assetsPanel: AssetsPanel!
    
    private let toolbarSize: Float = 50
    
    private var objectIcon: MTLTexture!
    private var faceIcon: MTLTexture!
    private var edgeIcon: MTLTexture!
    
    var selectionMode: SelectionMode = .object {
        didSet {
            BrushScene.current.selected?.isSelected = true
        }
    }
    
    var onLoadNewMap: ((URL)->Void)?
    
    static var current: EditorLayer!
    
    init(view: MTKView, sceneViewport: Viewport, topViewport: Viewport)
    {
        self.view = view
        
        _ = ImGuiCreateContext(nil)
        ImGui_ImplOSX_Init(view)
        
        ImGuiStyleColorsDark(nil)
        
        setStyles()
        
        ImGui_ImplMetal_Init(Engine.device)
        
        viewportPanel = ViewportPanel(viewport: sceneViewport)
        topViewPanel = OrthoViewPanel(viewport: topViewport)
        hierarchyPanel = HierarchyPanel()
        inspectorPanel = InspectorPanel()
        assetsPanel = AssetsPanel()

        assetsPanel.onLoadNewMap = { [weak self] url in
            self?.onLoadNewMap?(url)
        }
        
        objectIcon = TextureManager.shared.getTexture(for: "Assets/editor/toolbar_object_ic.png")
        faceIcon  = TextureManager.shared.getTexture(for: "Assets/editor/toolbar_face_ic.png")
        edgeIcon  = TextureManager.shared.getTexture(for: "Assets/editor/toolbar_edge_ic.png")
        
        EditorLayer.current = self
    }
    
    func dropFile(_ url: URL)
    {
        assetsPanel.dropFile(url)
    }
    
    func updateWorkingDir()
    {
        assetsPanel.updateWorkingDir()
    }
    
    func handleEvent(_ event: NSEvent)
    {
        ImGui_ImplOSX_HandleEvent(event, view)
        
        if viewportPanel.isHovered || topViewPanel.isHovered
        {
            handleInGame(event)
        }
    }
    
    private func handleInGame(_ event: NSEvent)
    {
        if event.type == .keyDown
        {
            Keyboard.setKey(event.keyCode, isPressed: true)
        }
        else if event.type == .keyUp
        {
            Keyboard.setKey(event.keyCode, isPressed: false)
        }
        else if event.type == .rightMouseDown
        {
            // HACK!!!
            if !viewportPanel.isPlaying
            {
                NSCursor.hide()
                CGAssociateMouseAndMouseCursorPosition(0)
            }
            
            Mouse.setMouseButton(event.buttonNumber, isPressed: true)
        }
        else if event.type == .rightMouseUp
        {
            // HACK!!!
            if !viewportPanel.isPlaying
            {
                NSCursor.unhide()
                CGAssociateMouseAndMouseCursorPosition(1)
            }
                
            Mouse.setMouseButton(event.buttonNumber, isPressed: false)
        }
        else if event.type == .mouseMoved || event.type == .leftMouseDragged || event.type == .rightMouseDragged
        {
            let deltaChange = float2(Float(event.deltaX), Float(event.deltaY))
            let posX = Float(event.locationInWindow.x)
            let posY = Float(view.bounds.height - event.locationInWindow.y)
            
            Mouse.setMousePositionChange(overallPosition: float2(posX, posY),
                                         deltaPosition: deltaChange)
        }
        else if event.type == .scrollWheel
        {
            Mouse.scrollWheel(Float(event.deltaY))
        }
        else if event.type == .leftMouseDown
        {
            Mouse.setMouseButton(0, isPressed: true)
        }
        else if event.type == .leftMouseUp
        {
            Mouse.setMouseButton(0, isPressed: false)
        }
        
        Keyboard.setKey(KeyCodes.shift.rawValue, isPressed: NSEvent.modifierFlags.contains(.shift))
    }
    
    // Draw grid for viewports
    func specialDraw(with renderer: ForwardRenderer)
    {
        viewportPanel.drawSpecial(with: renderer)
        topViewPanel.drawSpecial(with: renderer)
    }
    
    func draw()
    {
        guard view.bounds.size.width > 0, view.bounds.size.height > 0 else {
            return
        }
        
        guard let commandBuffer = Engine.commandQueue.makeCommandBuffer() else { return }
        commandBuffer.label = "Editor Command Buffer"
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.pushDebugGroup("ImGui")
        
        // Start the Dear ImGui frame
        ImGui_ImplMetal_NewFrame(renderPassDescriptor)
        ImGui_ImplOSX_NewFrame(view)
        ImGuiNewFrame()
        
        drawDocker()
        drawToolbar()
        
        ImGuiEndFrame()
        
        // Rendering
        ImGuiRender()
        let drawData = ImGuiGetDrawData()!
        ImGui_ImplMetal_RenderDrawData(drawData.pointee, commandBuffer, renderEncoder)
        
        if (ImGuiGetIO()!.pointee.ConfigFlags & Im(ImGuiConfigFlags_ViewportsEnable)) != 0
        {
            ImGuiUpdatePlatformWindows()
            ImGuiRenderPlatformWindowsDefault(nil, nil)
        }
        
        renderEncoder.popDebugGroup()
        renderEncoder.endEncoding()
        commandBuffer.present(view.currentDrawable!)
        
        commandBuffer.commit()
    }
    
    private func drawToolbar()
    {
        let viewport = ImGuiGetMainViewport()!
        ImGuiSetNextWindowPos(viewport.pointee.Pos, Im(ImGuiCond_None), ImVec2(0, 0))
        ImGuiSetNextWindowSize(viewport.pointee.Size, Im(ImGuiCond_None))
        ImGuiSetNextWindowViewport(viewport.pointee.ID)
        
        let windowFlags: ImGuiWindowFlags =
            Im(ImGuiWindowFlags_NoDocking)              |
//            Im(ImGuiWindowFlags_MenuBar)                |
            Im(ImGuiWindowFlags_NoTitleBar)             |
            Im(ImGuiWindowFlags_NoCollapse)             |
            Im(ImGuiWindowFlags_NoResize)               |
            Im(ImGuiWindowFlags_NoMove)                 |
            Im(ImGuiWindowFlags_NoBringToFrontOnFocus)  |
            Im(ImGuiWindowFlags_NoNavFocus)
        
        ImGuiPushStyleVar(Im(ImGuiStyleVar_WindowRounding), 0.0)
        ImGuiPushStyleVar(Im(ImGuiStyleVar_WindowBorderSize), 0.0)
        ImGuiPushStyleVar(Im(ImGuiStyleVar_WindowPadding), ImVec2(0, 0))
        
        ImGuiBegin("Toolbar", nil, windowFlags)
        
        ImGuiPopStyleVar(3)
        
        ImGuiSameLine(6, 0)
        drawSelectionModeButton(.object)
        ImGuiSameLine(0, 6)
        drawSelectionModeButton(.face)
        ImGuiSameLine(0, 6)
        drawSelectionModeButton(.edge)
        
        ImGuiEnd()
    }
    
    private func drawSelectionModeButton(_ mode: SelectionMode)
    {
        ImGuiPushID("SelectiomModeButton\(mode.rawValue)")
        
        let col = selectionMode == mode ? ImGuiTheme.enabled : ImVec4(0, 0, 0, 0)
        
        ImGuiPushStyleColor(Im(ImGuiCol_Button), col)
        ImGuiPushStyleColor(Im(ImGuiCol_ButtonHovered), col)
        ImGuiPushStyleColor(Im(ImGuiCol_ButtonActive), col)
        
        var icon: UnsafeMutableRawPointer
        
        switch mode
        {
            case .object:
                icon = withUnsafePointer(to: &objectIcon) { ptr in
                    return UnsafeMutableRawPointer(mutating: ptr)
                }

            case .face:
                icon = withUnsafePointer(to: &faceIcon) { ptr in
                    return UnsafeMutableRawPointer(mutating: ptr)
                }
                
            case .edge, .vertex:
                icon = withUnsafePointer(to: &edgeIcon) { ptr in
                    return UnsafeMutableRawPointer(mutating: ptr)
                }
        }
        
        ImGuiImageButton(
            icon,
            ImVec2(32, 32),
            ImVec2(0, 0),
            ImVec2(1, 1),
            0,
            col,
            ImVec4(1, 1, 1, 1)
        )
        
        if ImGuiIsItemClicked(Im(ImGuiMouseButton_Left)) {
            selectionMode = mode
        }
        
        ImGuiPopStyleColor(3)
        
        ImGuiPopID()
    }
    
    private func drawDocker()
    {
        // We are using the ImGuiWindowFlags_NoDocking flag to make the parent window not dockable into,
        // because it would be confusing to have two docking targets within each others.
        var windowFlags: ImGuiWindowFlags =
            Im(ImGuiWindowFlags_NoDocking)              |
//            Im(ImGuiWindowFlags_MenuBar)                |
            Im(ImGuiWindowFlags_NoTitleBar)             |
            Im(ImGuiWindowFlags_NoCollapse)             |
            Im(ImGuiWindowFlags_NoResize)               |
            Im(ImGuiWindowFlags_NoMove)                 |
            Im(ImGuiWindowFlags_NoBringToFrontOnFocus)  |
            Im(ImGuiWindowFlags_NoNavFocus)
        
        let viewport = ImGuiGetMainViewport()!
        
        let viewportPos = viewport.pointee.Pos
        let viewportSize = viewport.pointee.Size
        
        let dockerPos = ImVec2(viewportPos.x, viewportPos.y + toolbarSize)
        let dockerSize = ImVec2(viewportSize.x, viewportSize.y - toolbarSize)
        
        ImGuiSetNextWindowPos(dockerPos, Im(ImGuiCond_None), ImVec2(0, 0))
        ImGuiSetNextWindowSize(dockerSize, Im(ImGuiCond_None))
        ImGuiSetNextWindowViewport(viewport.pointee.ID)
        
        ImGuiPushStyleVar(Im(ImGuiStyleVar_WindowRounding), 0.0)
        ImGuiPushStyleVar(Im(ImGuiStyleVar_WindowBorderSize), 0.0)
        ImGuiPushStyleVar(Im(ImGuiStyleVar_WindowPadding), ImVec2(0, 0))
        
        // When using ImGuiDockNodeFlags_PassthruCentralNode, DockSpace() will render our background
        // and handle the pass-thru hole, so we ask Begin() to not render a background.
        if (Im(ImGuiDockNodeFlags_None) & Im(ImGuiDockNodeFlags_PassthruCentralNode)) != 0
        {
            windowFlags |= Im(ImGuiWindowFlags_NoBackground)
        }
        
        ImGuiBegin("DockSpace", nil, windowFlags)
        ImGuiPopStyleVar(3)
        
        let window_id = ImGuiGetID("DockSpace")
        
        if ImGuiDockBuilderGetNode(window_id) == nil
        {
            // Reset current docking state
            ImGuiDockBuilderRemoveNode(window_id)
            _ = ImGuiDockBuilderAddNode(window_id, Im(ImGuiDockNodeFlags_None))
            ImGuiDockBuilderSetNodeSize(window_id, ImGuiGetMainViewport().pointee.Size)

            var dock_main_id       = window_id
            var dock_right_id      = ImGuiDockBuilderSplitNode(dock_main_id, Im(ImGuiDir_Right), 0.15, nil, &dock_main_id)
            let dock_left_id      = ImGuiDockBuilderSplitNode(dock_main_id, Im(ImGuiDir_Left), 0.5, nil, &dock_main_id)
            let dock_right_down_id = ImGuiDockBuilderSplitNode(dock_right_id, Im(ImGuiDir_Down), 0.6, nil, &dock_right_id)
//            var dock_down_id       = ImGuiDockBuilderSplitNode(dock_main_id, Im(ImGuiDir_Down), 0.25, nil, &dock_main_id)
//            var dock_down_right_id = ImGuiDockBuilderSplitNode(dock_down_id, Im(ImGuiDir_Right), 0.6, nil, &dock_down_id)

            // Dock windows
            ImGuiDockBuilderDockWindow(hierarchyPanel.name, dock_right_id)
            ImGuiDockBuilderDockWindow(inspectorPanel.name, dock_right_down_id)
//            ImGuiDockBuilderDockWindow("Console",    dock_down_id)
            ImGuiDockBuilderDockWindow(topViewPanel.name, dock_left_id)
            ImGuiDockBuilderDockWindow(viewportPanel.name, dock_main_id)

            ImGuiDockBuilderFinish(dock_main_id)
        }
        
        ImGuiPushStyleVar(Im(ImGuiStyleVar_FrameBorderSize), 0)
        _ = ImGuiDockSpace(window_id, ImVec2(0, 0), Im(ImGuiDockNodeFlags_PassthruCentralNode), nil)
        ImGuiPopStyleVar(1)
        
        drawPanels()
        
        ImGuiEnd()
    }
    
    private func drawPanels()
    {
        hierarchyPanel.draw()
        inspectorPanel.draw()
        viewportPanel.draw()
        topViewPanel.draw()
//        assetsPanel.draw()
    }
    
    private func setStyles()
    {
        let style = ImGuiGetStyle()!
        
        ImGuiStyleColorsDark(nil)
        
        // Rounding
        style.pointee.WindowRounding = 4.0
        style.pointee.ChildRounding = 4.0
        style.pointee.FrameRounding = 4.0
        style.pointee.TabRounding = 4.0
        style.pointee.PopupRounding = 4.0
        style.pointee.GrabRounding = 3.0
        
        // Padding
        style.pointee.FramePadding = ImVec2(6, 3)
        
        // Size
        style.pointee.GrabMinSize = 11.0
        
        // Show/Hide
        style.pointee.WindowMenuButtonPosition = Im(ImGuiDir_None)

        ImGuiTheme.loadTheme()
        
//        if let workingDirURL = UserDefaults.standard.url(forKey: "workingDir")
//        {
//            iniPath = workingDirURL.appendingPathComponent("editor.ini").path
//            ImGuiGetIO().pointee.IniFilename = (iniPath as NSString).utf8String
//        }
//        else
//        {
//            openFileDialog()
//        }
        
        setFonts()
    }
    
    private func openFileDialog()
    {
        let dialog = NSOpenPanel()

        dialog.title = "Choose a working directory"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = true
        dialog.canChooseFiles = false

        if dialog.runModal() == .OK, let workingDirURL = dialog.url
        {
            iniPath = workingDirURL.appendingPathComponent("editor.ini").path
            ImGuiGetIO().pointee.IniFilename = (iniPath as NSString).utf8String
            
            UserDefaults.standard.set(workingDirURL, forKey: "workingDir")
        }
        else
        {
            exit(0)
        }
    }
}

private extension EditorLayer
{
    private static var iconRanges: [ImWchar] = [0xe00f, 0xf8ff, 0]
    private static var config: ImFontConfig = ImFontConfig_ImFontConfig().pointee  // don't use ImFontConfig()
    
    private func setFonts()
    {
        let io = ImGuiGetIO()!
        
        let dpi: Float = 2.0
        let fontSize = Float(17.0)
        let scaledFontSize = Float(dpi * fontSize)
        let iconFontSize = Float(12.0)
        let iconScaledFontSize = Float(dpi * iconFontSize)
        io.pointee.FontGlobalScale = 1 / dpi
        
        guard let fontBold = ResourceManager.getURL(for: "Assets/fonts/Ruda/Ruda-Bold.ttf")?.path,
              let fontSolidIcon = ResourceManager.getURL(for: "Assets/fonts/FontAwesome5/fa-solid-900.ttf")?.path,
              let fontRegularIcon = ResourceManager.getURL(for: "Assets/fonts/FontAwesome5/fa-regular-400.ttf")?.path,
              let fontBrandsIcon = ResourceManager.getURL(for: "Assets/fonts/FontAwesome5/fa-brands-400.ttf")?.path
        else {
            return
        }
        
        io.pointee.FontDefault = ImFontAtlas_AddFontFromFileTTF(io.pointee.Fonts, fontBold, scaledFontSize, nil, nil)
        ImGuiFontLibrary.defaultFont = io.pointee.FontDefault
        
        // FontAwesome5
        Self.config.MergeMode = true
        Self.config.GlyphMinAdvanceX = scaledFontSize  // Use if you want to make the icon monospaced
        ImGuiFontLibrary.regularIcon = ImFontAtlas_AddFontFromFileTTF(io.pointee.Fonts, fontSolidIcon, iconScaledFontSize, &Self.config, &Self.iconRanges)
        ImFontAtlas_AddFontFromFileTTF(io.pointee.Fonts, fontRegularIcon, iconScaledFontSize, &Self.config, &Self.iconRanges)
        ImFontAtlas_AddFontFromFileTTF(io.pointee.Fonts, fontBrandsIcon, iconScaledFontSize, &Self.config, &Self.iconRanges)
        
        // Large Icons
        let largeScale: Float = 1.8
        Self.config.MergeMode = false
        ImGuiFontLibrary.largeIcon = ImFontAtlas_AddFontFromFileTTF(io.pointee.Fonts, fontSolidIcon, iconScaledFontSize * largeScale, &Self.config, &Self.iconRanges)
        Self.config.MergeMode = true
        ImFontAtlas_AddFontFromFileTTF(io.pointee.Fonts, fontRegularIcon, iconScaledFontSize * largeScale, &Self.config, &Self.iconRanges)
        ImFontAtlas_AddFontFromFileTTF(io.pointee.Fonts, fontBrandsIcon, iconScaledFontSize * largeScale, &Self.config, &Self.iconRanges)
    }
}
