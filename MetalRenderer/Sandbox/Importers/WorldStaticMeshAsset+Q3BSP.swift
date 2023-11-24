//
//  WorldStaticMeshAsset+Q3BSP.swift
//  Sandbox
//
//  Created by Fedor Artemenkov on 01.10.2023.
//

import Foundation
import Quake3BSP
import simd

extension WorldStaticMeshAsset
{
    static func make(from bsp: Q3Map, folder: URL) -> WorldStaticMeshAsset
    {
        var asset = WorldStaticMeshAsset()
        asset.dirURL = folder
        
        var vertexlit: Dictionary<String, [UInt32]> = [:]
        var lightmapped: Dictionary<String, [UInt32]> = [:]
        
        for face in bsp.faces
        {
            if face.textureName == "noshader" { continue }
            if face.textureName.contains("sky") { continue }
            
            let key = face.textureName
            
            if face.type == .mesh
            {
                if vertexlit[key] == nil {
                    vertexlit[key] = []
                }
                
                vertexlit[key]?.append(contentsOf: face.vertexIndices)
            }
            else
            {
                if lightmapped[key] == nil {
                    lightmapped[key] = []
                }
                
                lightmapped[key]?.append(contentsOf: face.vertexIndices)
            }
        }
        
        for (key, indices) in vertexlit
        {
            let textureIndex = bsp.textures.firstIndex(where: { $0.texureName == key }) ?? -1

            let surface = Surface(
                firstIndex: asset.indices.count,
                indexCount: indices.count,
                textureIndex: textureIndex,
                isLightmapped: false
            )

            asset.surfaces.append(surface)
            asset.indices.append(contentsOf: indices)
        }
        
        for (key, indices) in lightmapped
        {
            let textureIndex = bsp.textures.firstIndex(where: { $0.texureName == key }) ?? -1

            let surface = Surface(
                firstIndex: asset.indices.count,
                indexCount: indices.count,
                textureIndex: textureIndex,
                isLightmapped: true
            )
            
            asset.surfaces.append(surface)
            asset.indices.append(contentsOf: indices)
        }
        
        asset.textures = bsp.textures.map { $0.texureName }
        
        let atlas = makeAtlas(from: bsp.lightmaps)
        
        var processedVertices = Array<Bool>.init(repeating: false, count: bsp.vertices.count)
        
        for face in bsp.faces
        {
            guard face.lightmapIndex >= 0 else { continue }

            let lm = atlas.parts[face.lightmapIndex]
            let width = Float(atlas.width)
            let height = Float(atlas.height)

            for i in face.vertexIndices.map({ Int($0) })
            {
                if processedVertices[i] { continue }
                
                bsp.vertices[i].lightmapCoord.x = (bsp.vertices[i].lightmapCoord.x * Float(lm.width) + Float(lm.x)) / width
                bsp.vertices[i].lightmapCoord.y = (bsp.vertices[i].lightmapCoord.y * Float(lm.height) + Float(lm.y)) / height
                
                processedVertices[i] = true
            }
        }
        
        asset.vertices = bsp.vertices.map {
            WorldStaticMeshAsset.Vertex(
                position: $0.position,
                texCoord0: $0.textureCoord,
                texCoord1: $0.lightmapCoord,
                color: $0.color
            )
        }
        
        let size = atlas.height * atlas.height * 4
        var atlasBytes = Array<UInt8>.init(repeating: 0, count: size)
        
        for part in atlas.parts
        {
            let targetX = part.x
            let targetY = part.y

            for sourceY in 0 ..< part.height
            {
                for sourceX in 0 ..< part.width
                {
                    let from = (sourceY * 128 * 4) + (sourceX * 4) // 4 bytes per pixel (assuming RGBA)
                    let to = ((targetY + sourceY) * atlas.height * 4) + ((targetX + sourceX) * 4) // same format as source

                    for channel in 0 ..< 4
                    {
                        atlasBytes[to + channel] = part.bytes[from + channel]
                    }
                }
            }
        }
        
        let data = TextureManager.shared.pngDataFrom(bytes: atlasBytes,
                                                     width: atlas.width,
                                                     height: atlas.height,
                                                     componentsCount: atlas.bytesPerComponent)
        
        let url = folder.appendingPathComponent("lightmap.png")
        try? data?.write(to: url)
        
        return asset
    }
    
    static func make(from bsp: Q3Map) -> (WorldStaticMeshAsset, LightmapAtlas)
    {
        var asset = WorldStaticMeshAsset()
        
        var vertexlit: Dictionary<String, [UInt32]> = [:]
        var lightmapped: Dictionary<String, [UInt32]> = [:]
        
        for face in bsp.faces
        {
            if face.textureName == "noshader" { continue }
            if face.textureName.contains("sky") { continue }
            
            let key = face.textureName
            
            if face.type == .mesh
            {
                if vertexlit[key] == nil {
                    vertexlit[key] = []
                }
                
                vertexlit[key]?.append(contentsOf: face.vertexIndices)
            }
            else
            {
                if lightmapped[key] == nil {
                    lightmapped[key] = []
                }
                
                lightmapped[key]?.append(contentsOf: face.vertexIndices)
            }
        }
        
        for (key, indices) in vertexlit
        {
            let textureIndex = bsp.textures.firstIndex(where: { $0.texureName == key }) ?? -1

            let surface = Surface(
                firstIndex: asset.indices.count,
                indexCount: indices.count,
                textureIndex: textureIndex,
                isLightmapped: false
            )

            asset.surfaces.append(surface)
            asset.indices.append(contentsOf: indices)
        }
        
        for (key, indices) in lightmapped
        {
            let textureIndex = bsp.textures.firstIndex(where: { $0.texureName == key }) ?? -1

            let surface = Surface(
                firstIndex: asset.indices.count,
                indexCount: indices.count,
                textureIndex: textureIndex,
                isLightmapped: true
            )
            
            asset.surfaces.append(surface)
            asset.indices.append(contentsOf: indices)
        }
        
        asset.textures = bsp.textures.map { $0.texureName }
        
        let atlas = makeAtlas(from: bsp.lightmaps)
        
        var processedVertices = Array<Bool>.init(repeating: false, count: bsp.vertices.count)
        
        for face in bsp.faces
        {
            guard face.lightmapIndex >= 0 else { continue }

            let lm = atlas.parts[face.lightmapIndex]
            let width = Float(atlas.width)
            let height = Float(atlas.height)

            for i in face.vertexIndices.map({ Int($0) })
            {
                if processedVertices[i] { continue }
                
                bsp.vertices[i].lightmapCoord.x = (bsp.vertices[i].lightmapCoord.x * Float(lm.width) + Float(lm.x)) / width
                bsp.vertices[i].lightmapCoord.y = (bsp.vertices[i].lightmapCoord.y * Float(lm.height) + Float(lm.y)) / height
                
                processedVertices[i] = true
            }
        }
        
        asset.vertices = bsp.vertices.map {
            WorldStaticMeshAsset.Vertex(
                position: $0.position,
                texCoord0: $0.textureCoord,
                texCoord1: $0.lightmapCoord,
                color: $0.color
            )
        }
        
        return (asset, atlas)
    }
}

private func makeAtlas(from lightmaps: [Q3Lightmap]) -> LightmapAtlas
{
    var atlas = LightmapAtlas()
    
    let count = lightmaps.count
    let gridSize = Int(ceil(sqrt(Float(count))))
    
    let textureSize = gridSize * 128
        
    var xOffset: Int = 0
    var yOffset: Int = 0
    
    atlas.width = gridSize * 128
    atlas.height = gridSize * 128
    atlas.bytesPerComponent = 4
    
    for i in 0 ..< count
    {
        atlas.parts.append(
            LightmapPart(
                x: xOffset,
                y: yOffset,
                width: 128,
                height: 128,
                bytes: lightmaps[i].flatMap({ [$0.0, $0.1, $0.2, $0.3] })
            )
        )
        
        xOffset += 128
        
        if xOffset >= textureSize
        {
            yOffset += 128
            xOffset = 0
        }
    }
    
    return atlas
}

struct LightmapAtlas
{
    var width: Int = 0
    var height: Int = 0
    var bytesPerComponent: Int = 0
    var parts: [LightmapPart] = []
    
    func getPngData() -> Data?
    {
        let size = height * height * 4
        var imageBytes = Array<UInt8>.init(repeating: 0, count: size)
        
        for part in parts
        {
            let targetX = part.x
            let targetY = part.y

            for sourceY in 0 ..< part.height
            {
                for sourceX in 0 ..< part.width
                {
                    let from = (sourceY * 128 * 4) + (sourceX * 4) // 4 bytes per pixel (assuming RGBA)
                    let to = ((targetY + sourceY) * height * 4) + ((targetX + sourceX) * 4) // same format as source

                    for channel in 0 ..< 4
                    {
                        imageBytes[to + channel] = part.bytes[from + channel]
                    }
                }
            }
        }
        
        return TextureManager.shared.pngDataFrom(bytes: imageBytes,
                                                 width: width,
                                                 height: height,
                                                 componentsCount: bytesPerComponent)
    }
}

struct LightmapPart
{
    let x, y: Int
    let width, height: Int
    let bytes: [UInt8]
}
