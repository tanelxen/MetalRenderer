//
//  AssetsPanel.swift
//  Sandbox
//
//  Created by Fedor Artemenkov on 12.09.2023.
//

import Cocoa
import ImGui
import Metal

import GoldSrcMDL
import Quake3BSP

import SwiftZip

import RecastObjC
//import RecastNavmesh

final class AssetsPanel
{
    let name = "Assets"
    
    private var baseDir: URL?
    private var assetsDir: URL?
    private var currentDir: URL?
    
    private var dirIcon: MTLTexture?
    private var fileIcon: MTLTexture?
    private var assetIcon: MTLTexture?
    
    private var items: [AssetsPanelItem] {
        
        guard let currentDir = self.currentDir else { return [] }
        
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: currentDir,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        ) else { return [] }
        
        return urls.map {
            let isDir = (try! $0.resourceValues(forKeys: [.isDirectoryKey])).isDirectory!
            let name = $0.deletingPathExtension().lastPathComponent
//            let ext = $0.pathExtension
            
            let type: ItemType = isDir ? .folder : .file
            
            return AssetsPanelItem(url: $0, name: name, type: type)
        }
    }
    
    var onLoadNewMap: ((URL)->Void)?
    
    init()
    {
        dirIcon = TextureManager.shared.getTexture(for: "Assets/dir_ic.png")
        fileIcon = TextureManager.shared.getTexture(for: "Assets/file_ic.png")
        assetIcon = TextureManager.shared.getTexture(for: "Assets/asset_ic.png")
        
        updateWorkingDir()
    }
    
    func updateWorkingDir()
    {
        baseDir = UserDefaults.standard.url(forKey: "workingDir")
        
        if let dir = baseDir?.appendingPathComponent("Assets"), FileManager.default.fileExists(atPath: dir.path)
        {
            assetsDir = dir
            currentDir = dir
        }
        else
        {
            assetsDir = nil
            currentDir = nil
        }
    }
    
    func draw()
    {
        ImGuiBegin(name, nil, 0)
        
        guard baseDir != nil else {
            
            ImGuiTextV("\u{f6e2} Working dir wasn't located! \u{f6e2}")
            
            if ImGuiButton("Locate")
            {
                locateWorkingDir()
            }
            
            ImGuiEnd()
            return
        }
        
        guard assetsDir != nil else {
            
            ImGuiTextWrappedV("Your working dir:\n" + baseDir!.path)
            ImGuiTextV("\u{f6e2} 'Assets' dir is missing! \u{f6e2}")
            
            if ImGuiButton("Create")
            {
                createAssetsDir()
            }
            
            ImGuiEnd()
            return
        }
        
        drawContent()
        
        ImGuiEnd()
    }
    
    func dropFile(_ url: URL)
    {
        if url.pathExtension == "mdl"
        {
            makeImportValveModel(url)
            return
        }
        
        if url.pathExtension == "bsp"
        {
            makeImportQuakeBSP(url)
            return
        }
    }
    
    private func drawContent()
    {
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
        
//        if ImGuiBeginPopupContextWindow("Asset empty popup", Im(ImGuiPopupFlags_MouseButtonRight) | Im(ImGuiPopupFlags_NoOpenOverItems))
//        {
//            if ImGuiSelectable("New folder", false, Im(ImGuiSelectableFlags_None), ImVec2(0))
//            {
//                print("Create new folder")
//            }
//
//            if ImGuiSelectable("Import", false, Im(ImGuiSelectableFlags_None), ImVec2(0))
//            {
//                print("Import asset")
//            }
//
//            ImGuiEndPopup()
//        }
    }
    
    private func makeImportValveModel(_ url: URL)
    {
        guard let currentDir = self.currentDir else { return }
        
        guard let data = try? Data(contentsOf: url)
        else
        {
            print("Invalid data for filepath: \(url.path)")
            return
        }
        
        let model = GoldSrcMDL(data: data).valveModel
        let asset = SkeletalMeshAsset.make(from: model)
        
        let name = url.deletingPathExtension().lastPathComponent
        if let folder = ResourceManager.getOrCreateFolder(named: "\(name).skl", directory: currentDir)
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
    
    private func makeImportQuakeBSP(_ url: URL)
    {
        guard let currentDir = self.currentDir else { return }
        
        guard let data = try? Data(contentsOf: url)
        else
        {
            print("Invalid data for filepath: \(url.path)")
            return
        }
        
        let name = url.deletingPathExtension().lastPathComponent
        
        let bsp = Q3Map(data: data)
        let (worldmesh, lightmap) = WorldStaticMeshAsset.make(from: bsp)
        
        let entities = WorldEntitiesAsset.make(from: bsp)
        let collision = WorldCollisionAsset.make(from: bsp)
        
        var verts = bsp.vertices.flatMap({ [$0.position.x, $0.position.z, -$0.position.y] })
        let nverts = Int32(bsp.vertices.count)
        
        var tris: [Int32] = []
        var ntris: Int32 = 0
        
        for face in bsp.faces
        {
            if face.textureName == "noshader" { continue }
            if face.textureName.contains("sky") { continue }
            
            for poly in face.vertexIndices.chunked(into: 3)
            {
                let indices: [Int32] = [ Int32(poly[0]), Int32(poly[2]), Int32(poly[1]) ]
                tris.append(contentsOf: indices)
                
                ntris += 1
            }
        }
        
        let navmesh = Navmesh()
        navmesh.calculateVerts(&verts, nverts: nverts, tris: &tris, ntris: ntris)
        
        do
        {
            let archiveUrl = currentDir.appendingPathComponent(name).appendingPathExtension("wld")
            
            // Open an archive for writing, overwriting any existing file
            let archive = try ZipMutableArchive(url: archiveUrl, flags: [.create, .truncate])

            // Create a data source and add it to the archive
            let worldmeshData = worldmesh.toData()
            
            if let source = try? ZipSource(data: worldmeshData)
            {
                try archive.addFile(name: "worldmesh.bin", source: source)
            }
            
            if let data = lightmap.getPngData(), let source = try? ZipSource(data: data)
            {
                try archive.addFile(name: "lightmap.png", source: source)
            }
            
            let encoder = JSONEncoder()
            
            if let data = try? encoder.encode(entities), let source = try? ZipSource(data: data)
            {
                try archive.addFile(name: "entities.json", source: source)
            }
            
            if let data = try? encoder.encode(collision), let source = try? ZipSource(data: data)
            {
                try archive.addFile(name: "collision.json", source: source)
            }
            
            if let data = navmesh.getMeshJson(), let source = try? ZipSource(data: data)
            {
                try archive.addFile(name: "navmesh.json", source: source)
            }

            try archive.close()
        }
        catch
        {
            // Handle possible errors
            print("\(error)")
        }
    }
    
    private func copyTextures(for bsp: Q3Map, from sourceDir: String)
    {
        for name in bsp.textures.map({ $0.texureName })
        {
            let fileURL = baseDir!.appendingPathComponent(sourceDir).appendingPathComponent(name)

            let jpg = fileURL.appendingPathExtension("jpg")
            let tga = fileURL.appendingPathExtension("tga")

            var sourceURL: URL?

            if FileManager.default.fileExists(atPath: jpg.path)
            {
                sourceURL = jpg
            }
            else if FileManager.default.fileExists(atPath: tga.path)
            {
                sourceURL = tga
            }

            if let source = sourceURL
            {
                let folderName = "Assets/" + URL(string: name)!.deletingLastPathComponent().path

                if let destDir = ResourceManager.getOrCreateFolder(named: folderName, directory: baseDir!)
                {
                    let ext = source.pathExtension
                    let filename = source.deletingPathExtension().lastPathComponent

                    let dest = destDir.appendingPathComponent(filename).appendingPathExtension(ext)
                    
                    if !FileManager.default.fileExists(atPath: dest.path)
                    {
                        try? FileManager.default.copyItem(at: source, to: dest)
                    }
                }
            }
            else
            {
                print("Failed: " + name)
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
        openPanel.allowedFileTypes = ["mdl", "bsp"]
        
        openPanel.begin { result in
            if result == .OK, let url = openPanel.url
            {
                self.dropFile(url)
            }
        }
    }
    
    private func locateWorkingDir()
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
            UserDefaults.standard.set(workingDirURL, forKey: "workingDir")
            updateWorkingDir()
        }
    }
    
    private func createAssetsDir()
    {
        guard let workingDir = baseDir else { return }
        
        assetsDir = ResourceManager.getOrCreateFolder(named: "Assets", directory: workingDir)
        currentDir = assetsDir
    }
    
    private func drawToolbar()
    {
        if ImGuiButton("Import")
        {
            openImportFileDialog()
        }

        if ImGuiArrowButton("Back", Im(ImGuiDir_Left)), currentDir != assetsDir
        {
            currentDir = currentDir?.deletingLastPathComponent()
        }
        
        ImGuiSameLine(0, 8)
        
        if let baseDir = self.baseDir, let currentDir = self.currentDir
        {
            let path = currentDir.path.replacingOccurrences(of: baseDir.path, with: "") + "/"
            ImGuiTextV(path)
        }
        else
        {
            ImGuiTextV("No such 'Assets' dir")
        }
        
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
            
//            if ImGuiBeginPopupContextWindow("Asset popup", Im(ImGuiPopupFlags_MouseButtonRight))
//            {
//                if ImGuiSelectable("Remove", false, Im(ImGuiSelectableFlags_None), ImVec2(0))
//                {
//                    print("Remove asset \(item.name)")
//                }
//
//                if ImGuiSelectable("Reimport", false, Im(ImGuiSelectableFlags_None), ImVec2(0))
//                {
//                    print("Reimport asset \(item.name)")
//                }
//
//                ImGuiEndPopup()
//            }
            
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
                
            case .file:
                if item.url.pathExtension == "wld"
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
        }
    }
}

private enum ItemType
{
    case folder
    case file
}

private struct AssetsPanelItem
{
    let url: URL
    let name: String
    let type: ItemType
}

