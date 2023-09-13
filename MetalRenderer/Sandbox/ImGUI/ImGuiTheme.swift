//
//  ImGuiTheme.swift
//  Palico
//
//  Created by Junhao Wang on 1/15/22.
//

import ImGui

struct ImGuiTheme
{
    // Theme
    static var mainTheme          = ImVec4(0.84, 0.65, 0.19, 1.0)
    
    static var componentX         = ImVec4(0.80, 0.35, 0.35, 1.0)
    static var componentHoveredX  = ImVec4(0.90, 0.35, 0.35, 1.0)
    
    static var componentY         = ImVec4(0.35, 0.80, 0.35, 1.0)
    static var componentHoveredY  = ImVec4(0.40, 0.85, 0.40, 1.0)
    
    static var componentZ         = ImVec4(0.35, 0.56, 0.76, 1.0)
    static var componentHoveredZ  = ImVec4(0.40, 0.65, 0.90, 1.0)
    
    // Console
    static var consoleDebug       = ImVec4(0.40, 0.90, 0.40, 1.0)
    static var consoleInfo        = text
    static var consoleWarn        = ImVec4(0.90, 0.90, 0.40, 1.0)
    static var consoleError       = ImVec4(0.90, 0.40, 0.40, 1.0)
    
    // General
    static var windowBg           = ImVec4(0.15, 0.15, 0.15, 1.0)
    static var popupBg            = ImVec4(0.15, 0.15, 0.15, 0.95)
    static var text               = ImVec4(0.90, 0.90, 0.90, 1.0)
    
    static var normal             = ImVec4(0.20, 0.21, 0.21, 1.0)
    static var hovered            = ImVec4(0.30, 0.30, 0.30, 1.0)
    static var active             = ImVec4(0.15, 0.15, 0.15, 1.0)
    
    static var enabled            = ImVec4(0.30, 0.30, 0.30, 1.0)
    static var disabled           = ImVec4(0.20, 0.21, 0.21, 1.0)
    
    static var tabNormal          = ImVec4(0.15, 0.15, 0.15, 1.0)
    static var tabHovered         = ImVec4(0.38, 0.38, 0.38, 1.0)
    static var tabActive          = ImVec4(0.28, 0.28, 0.28, 1.0)
    static var tabUnfocused       = ImVec4(0.15, 0.15, 0.15, 1.0)
    static var tabUnfocusedActive = ImVec4(0.20, 0.21, 0.21, 1.0)
    
    static var titleBg            = ImVec4(0.15, 0.15, 0.15, 1.0)
    static var titleBgActive      = ImVec4(0.15, 0.15, 0.15, 1.0)
    static var titleBgCollapsed   = ImVec4(0.15, 0.15, 0.15, 1.0)
    
    static var separator          = ImVec4(0.23, 0.23, 0.23, 0.5)
    static var separatorHovered   = ImVec4(0.23, 0.23, 0.23, 0.8)
    static var separatorActive    = ImVec4(0.23, 0.23, 0.23, 0.8)
    
    static var scrollBarBg        = windowBg
    
    static func loadTheme()
    {
//        withUnsafeMutableBytes(of: &ImGuiGetStyle().pointee.Colors) { raw in
//
//            let ptr = raw.baseAddress!.assumingMemoryBound(to: ImVec4.self)
//            let count = raw.count / MemoryLayout<ImVec4>.stride
//
//            let colors = UnsafeMutableBufferPointer(start: ptr, count: count)
//
//            colors[Int(Im(ImGuiCol_WindowBg))]            = Self.windowBg
//            colors[Int(Im(ImGuiCol_PopupBg))]             = Self.popupBg
//            colors[Int(Im(ImGuiCol_Text))]                = Self.text
//
//            // Follow Main Theme Color
//            colors[Int(Im(ImGuiCol_DockingPreview))]      = Self.mainTheme
//            colors[Int(Im(ImGuiCol_CheckMark))]           = Self.mainTheme
//            colors[Int(Im(ImGuiCol_SliderGrab))]          = Self.mainTheme
//            colors[Int(Im(ImGuiCol_SliderGrabActive))]    = Self.mainTheme
//            colors[Int(Im(ImGuiCol_ResizeGrip))]          = Self.mainTheme
//
//            // Headers
//            colors[Int(Im(ImGuiCol_Header))]              = Self.normal
//            colors[Int(Im(ImGuiCol_HeaderHovered))]       = Self.hovered
//            colors[Int(Im(ImGuiCol_HeaderActive))]        = Self.active
//
//            // Buttons
//            colors[Int(Im(ImGuiCol_Button))]              = Self.normal
//            colors[Int(Im(ImGuiCol_ButtonHovered))]       = Self.hovered
//            colors[Int(Im(ImGuiCol_ButtonActive))]        = Self.active
//
//            // Frame BG
//            colors[Int(Im(ImGuiCol_FrameBg))]             = Self.normal
//            colors[Int(Im(ImGuiCol_FrameBgHovered))]      = Self.hovered
//            colors[Int(Im(ImGuiCol_FrameBgActive))]       = Self.active
//
//            // Tabs
//            colors[Int(Im(ImGuiCol_Tab))]                 = Self.tabNormal
//            colors[Int(Im(ImGuiCol_TabHovered))]          = Self.tabHovered
//            colors[Int(Im(ImGuiCol_TabActive))]           = Self.tabActive
//            colors[Int(Im(ImGuiCol_TabUnfocused))]        = Self.tabUnfocused
//            colors[Int(Im(ImGuiCol_TabUnfocusedActive))]  = Self.tabUnfocusedActive
//
//            // Title
//            colors[Int(Im(ImGuiCol_TitleBg))]             = Self.titleBg
//            colors[Int(Im(ImGuiCol_TitleBgActive))]       = Self.titleBgActive
//            colors[Int(Im(ImGuiCol_TitleBgCollapsed))]    = Self.titleBgCollapsed
//
//            // Separator
//            colors[Int(Im(ImGuiCol_Separator))]           = Self.separator
//            colors[Int(Im(ImGuiCol_SeparatorHovered))]    = Self.separatorHovered
//            colors[Int(Im(ImGuiCol_SeparatorActive))]     = Self.separatorActive
//
//            // ScrollBar
//            colors[Int(Im(ImGuiCol_ScrollbarBg))]         = Self.scrollBarBg
//        }
        
        ImGui.CArray<ImVec4>.write(&ImGuiGetStyle().pointee.Colors) { colors in
            colors[Int(Im(ImGuiCol_WindowBg))]            = Self.windowBg
            colors[Int(Im(ImGuiCol_PopupBg))]             = Self.popupBg
            colors[Int(Im(ImGuiCol_Text))]                = Self.text

            // Follow Main Theme Color
            colors[Int(Im(ImGuiCol_DockingPreview))]      = Self.mainTheme
            colors[Int(Im(ImGuiCol_CheckMark))]           = Self.mainTheme
            colors[Int(Im(ImGuiCol_SliderGrab))]          = Self.mainTheme
            colors[Int(Im(ImGuiCol_SliderGrabActive))]    = Self.mainTheme
            colors[Int(Im(ImGuiCol_ResizeGrip))]          = Self.mainTheme

            // Headers
            colors[Int(Im(ImGuiCol_Header))]              = Self.normal
            colors[Int(Im(ImGuiCol_HeaderHovered))]       = Self.hovered
            colors[Int(Im(ImGuiCol_HeaderActive))]        = Self.active

            // Buttons
            colors[Int(Im(ImGuiCol_Button))]              = Self.normal
            colors[Int(Im(ImGuiCol_ButtonHovered))]       = Self.hovered
            colors[Int(Im(ImGuiCol_ButtonActive))]        = Self.active

            // Frame BG
            colors[Int(Im(ImGuiCol_FrameBg))]             = Self.normal
            colors[Int(Im(ImGuiCol_FrameBgHovered))]      = Self.hovered
            colors[Int(Im(ImGuiCol_FrameBgActive))]       = Self.active

            // Tabs
            colors[Int(Im(ImGuiCol_Tab))]                 = Self.tabNormal
            colors[Int(Im(ImGuiCol_TabHovered))]          = Self.tabHovered
            colors[Int(Im(ImGuiCol_TabActive))]           = Self.tabActive
            colors[Int(Im(ImGuiCol_TabUnfocused))]        = Self.tabUnfocused
            colors[Int(Im(ImGuiCol_TabUnfocusedActive))]  = Self.tabUnfocusedActive

            // Title
            colors[Int(Im(ImGuiCol_TitleBg))]             = Self.titleBg
            colors[Int(Im(ImGuiCol_TitleBgActive))]       = Self.titleBgActive
            colors[Int(Im(ImGuiCol_TitleBgCollapsed))]    = Self.titleBgCollapsed

            // Separator
            colors[Int(Im(ImGuiCol_Separator))]           = Self.separator
            colors[Int(Im(ImGuiCol_SeparatorHovered))]    = Self.separatorHovered
            colors[Int(Im(ImGuiCol_SeparatorActive))]     = Self.separatorActive

            // ScrollBar
            colors[Int(Im(ImGuiCol_ScrollbarBg))]         = Self.scrollBarBg
        }
    }
}
