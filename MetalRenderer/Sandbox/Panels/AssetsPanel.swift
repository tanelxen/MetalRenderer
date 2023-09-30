//
//  AssetsPanel.swift
//  Sandbox
//
//  Created by Fedor Artemenkov on 12.09.2023.
//

import Foundation
import Cocoa
import ImGui
import Metal
import GoldSrcMDL

final class AssetsPanel
{
    let name = "Assets"
    
    private let baseDir: URL
    private let assetsDir: URL
    private var currentDir: URL
    
    private var dirIcon: MTLTexture?
    private var fileIcon: MTLTexture?
    private var assetIcon: MTLTexture?
    
    private var items: [AssetsPanelItem] {
        
        let urls = try! FileManager.default.contentsOfDirectory(
            at: currentDir,
            includingPropertiesForKeys: [.isPackageKey, .isDirectoryKey],
            options: .skipsHiddenFiles
        )
        
        return urls.map {
            let isDir = (try! $0.resourceValues(forKeys: [.isDirectoryKey])).isDirectory!
            let isPackage = (try! $0.resourceValues(forKeys: [.isPackageKey])).isPackage!
            let name = $0.deletingPathExtension().lastPathComponent
//            let ext = $0.pathExtension
            
            let type: ItemType = isPackage ? .asset : (isDir ? .folder : .file)
            
            return AssetsPanelItem(url: $0, name: name, type: type)
        }
    }
    
    var onLoadNewMap: ((URL)->Void)?
    
    init()
    {
        baseDir = UserDefaults.standard.url(forKey: "workingDir")!
        assetsDir = baseDir.appendingPathComponent("Assets")
        currentDir = assetsDir
        
        dirIcon = TextureManager.shared.getTexture(for: "Assets/dir_ic.png")
        fileIcon = TextureManager.shared.getTexture(for: "Assets/file_ic.png")
        assetIcon = TextureManager.shared.getTexture(for: "Assets/asset_ic.png")
    }
    
    func draw()
    {
        ImGuiBegin(name, nil, 0)
        
        drawToolbar()
        
        let padding: Float = 8
        let thumbnailSize: Float = 64
        let cellSize = thumbnailSize + padding
        
        var region = ImVec2()
        ImGuiGetContentRegionAvail(&region)

        let panelWidth = region.x
        let columnCount = max(1, Int(panelWidth / cellSize))
        
        ImGuiColumns(Int32(columnCount), nil, false)
        
        drawItems(thumbnailSize: thumbnailSize)
        
        ImGuiColumns(1, nil, false)
        
        ImGuiEnd()
    }
    
    func dropFile(_ url: URL)
    {
        guard url.pathExtension == "mdl"
        else
        {
            print("Unknown format for \(url.path)")
            return
        }
        
        guard let data = try? Data(contentsOf: url)
        else
        {
            print("Invalid data for filepath: \(url.path)")
            return
        }
        
        let model = GoldSrcMDL(data: data).valveModel
        let asset = SkeletalMeshAsset.make(from: model)
        
        let name = url.deletingPathExtension().lastPathComponent
        if let folder = ResourceManager.getOrCreateFolder(named: "\(name).asset", directory: currentDir)
        {
            asset.saveToFolder(folder)
            
            for texture in model.textures
            {
                let data = TextureManager.shared.pngDataFrom(bytes: texture.data,
                                                             width: texture.width,
                                                             height: texture.height,
                                                             componentsCount: 3)
                
                let url = folder.appendingPathComponent("\(texture.name).png")
                try? data?.write(to: url)
            }
        }
    }
    
    private func openImportFileDialog()
    {
        let openPanel = NSOpenPanel()

        openPanel.title = "Import file as asset"
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["mdl"]
        
        openPanel.begin { result in
            if result == .OK, let url = openPanel.url
            {
                self.dropFile(url)
            }
        }
    }
    
    private func drawToolbar()
    {
        if ImGuiButton("Import")
        {
            openImportFileDialog()
        }

        if ImGuiArrowButton("Back", Im(ImGuiDir_Left)), currentDir != assetsDir
        {
            currentDir = currentDir.deletingLastPathComponent()
        }
        
        ImGuiSameLine(0, 8)
        
        let path = currentDir.path.replacingOccurrences(of: baseDir.path, with: "") + "/"
        ImGuiTextV(path)
        
        ImGuiSeparator()
    }
    
    private func drawItems(thumbnailSize: Float)
    {
        for item in items
        {
            ImGuiPushID(item.name)
            
            ImGuiPushStyleColor(Im(ImGuiCol_Button), ImVec4(0, 0, 0, 0))
            ImGuiPushStyleColor(Im(ImGuiCol_ButtonActive), ImVec4(0, 0, 0, 0))
            ImGuiPushStyleColor(Im(ImGuiCol_ButtonHovered), ImVec4(0, 0, 0, 0))
            
            ImGuiImageButton(
                iconTextureId(for: item.type),
                ImVec2(thumbnailSize, thumbnailSize),
                ImVec2(0, 0),
                ImVec2(1, 1),
                0,
                ImVec4(0, 0, 0, 0),
                ImVec4(1, 1, 1, 1)
            )
            
            if ImGuiIsItemHovered(0) && ImGuiIsMouseDoubleClicked(Im(ImGuiMouseButton_Left))
            {
                processDoubleClick(item)
            }
            
            ImGuiPopStyleColor(3)
            
            ImGuiTextWrappedV(item.name)
            
            ImGuiNextColumn()
            ImGuiPopID()
        }
    }
    
    private func processDoubleClick(_ item: AssetsPanelItem)
    {
        switch item.type
        {
            case .folder:
                currentDir = item.url
                
            case .asset, .file:
                if item.url.pathExtension == "bsp"
                {
                    onLoadNewMap?(item.url)
                }
        }
    }
    
    private func iconTextureId(for itemType: ItemType) -> UnsafeMutableRawPointer
    {
        switch itemType
        {
            case .folder:
                return withUnsafePointer(to: &dirIcon) { ptr in
                    return UnsafeMutableRawPointer(mutating: ptr)
                }

            case .file:
                return withUnsafePointer(to: &fileIcon) { ptr in
                    return UnsafeMutableRawPointer(mutating: ptr)
                }

            case .asset:
                return withUnsafePointer(to: &assetIcon) { ptr in
                    return UnsafeMutableRawPointer(mutating: ptr)
                }
        }
    }
}

private enum ItemType
{
    case folder
    case asset
    case file
}

private struct AssetsPanelItem
{
    let url: URL
    let name: String
    let type: ItemType
}
