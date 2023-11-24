//
//  WorldAssetSerializer.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 30.09.2023.
//

import Foundation

extension WorldStaticMeshAsset
{
    static func load(from data: Data) -> WorldStaticMeshAsset?
    {
        let bytes = NSData(data: data).bytes
        
        let pData = UnsafeRawPointer(bytes)
        let header = pData.load(as: FileHeader.self)
        
        var asset = WorldStaticMeshAsset()
        
        asset.vertices = readChanks(for: header.vertices, in: bytes)
        asset.indices = readChanks(for: header.indices, in: bytes)
        
        let surfaces: [FileSurface] = readChanks(for: header.surfaces, in: bytes)
        
        asset.surfaces = surfaces.map {
            Surface(firstIndex: Int($0.firstIndex),
                    indexCount: Int($0.indexCount),
                    textureIndex: Int($0.textureIndex),
                    isLightmapped: $0.isLightmapped
            )
        }
        
        let textures: [Chars64] = readChanks(for: header.textures, in: bytes)
        asset.textures = textures.map { charsToString($0) }
        
        return asset
    }
    
    private static func readChanks<T>(for entry: EntryInfo, in bytes: UnsafeRawPointer) -> [T]
    {
        let count = Int(entry.length) / MemoryLayout<T>.stride
        return bytes.readItems(offset: Int(entry.offset), count: count)
    }
}

extension WorldStaticMeshAsset
{
    func toData() -> Data
    {
        let verticesData = verticesData()
        let indicesData = indicesData()
        let surfacesData = surfacesData()
        let texturesData = texturesData()
        
        var offset = Int32(MemoryLayout<FileHeader>.stride)
        
        let verticesEntry = EntryInfo(offset: offset, length: Int32(verticesData.count))
        offset += verticesEntry.length
        
        let indicesEntry = EntryInfo(offset: offset, length: Int32(indicesData.count))
        offset += indicesEntry.length
        
        let surfacesEntry = EntryInfo(offset: offset, length: Int32(surfacesData.count))
        offset += surfacesEntry.length
        
        let texturesEntry = EntryInfo(offset: offset, length: Int32(texturesData.count))
        offset += texturesEntry.length
        
        var header = FileHeader(
            vertices: verticesEntry,
            indices: indicesEntry,
            surfaces: surfacesEntry,
            textures: texturesEntry
        )
        
        var data = Data(bytes: &header, count: MemoryLayout<FileHeader>.stride)
        
        data.append(verticesData)
        data.append(indicesData)
        data.append(surfacesData)
        data.append(texturesData)
        
        return data
    }
    
    func saveToFolder(_ folder: URL)
    {

        let data = toData()
        
        do
        {
            let url = folder.appendingPathComponent("worldmesh.bin")
            try data.write(to: url)
        }
        catch
        {
            print(error.localizedDescription)
        }
    }
    
    private func texturesData() -> Data
    {
        var texturesData = Data()
        
        for name in textures
        {
            var source = name.asTuple64CChars
            let data = Data(bytes: &source, count: MemoryLayout<Chars64>.stride)
            texturesData.append(data)
        }
        
        return texturesData
    }
    
    private func indicesData() -> Data
    {
        var indicesData = Data()
        
        for index in indices
        {
            var source = index
            let data = Data(bytes: &source, count: MemoryLayout<UInt32>.stride)
            indicesData.append(data)
        }
        
        return indicesData
    }
    
    private func verticesData() -> Data
    {
        var verticesData = Data()
        
        for vertex in vertices
        {
            var source = vertex
            let data = Data(bytes: &source, count: MemoryLayout<Vertex>.stride)
            verticesData.append(data)
        }
        
        return verticesData
    }
    
    private func surfacesData() -> Data
    {
        var surfacesData = Data()
        
        for surface in surfaces
        {
            var fileSurface = FileSurface(
                firstIndex: Int32(surface.firstIndex),
                indexCount: Int32(surface.indexCount),
                textureIndex: Int32(surface.textureIndex),
                isLightmapped: surface.isLightmapped
            )
            
            let data = Data(bytes: &fileSurface, count: MemoryLayout<FileSurface>.stride)
            surfacesData.append(data)
        }
        
        return surfacesData
    }
}

private extension UnsafeRawPointer
{
    func readItems<T>(offset: Int, count: Int) -> Array<T>
    {
        let pointer = (self + offset).bindMemory(to: T.self, capacity: count)
        let buffer = UnsafeBufferPointer(start: pointer, count: count)
        
        return Array(buffer)
    }
}

private typealias Chars64 = (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                             CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                             CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                             CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                             CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                             CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                             CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                             CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar)

private func charsToString<T>(_ chars: T) -> String
{
    var bytes = chars
    
    return withUnsafeBytes(of: &bytes) { rawPtr in
        let ptr = rawPtr.baseAddress!.assumingMemoryBound(to: CChar.self)
        return String(cString: ptr)
    }
}

private extension String
{
    var asTuple64CChars: Chars64 {
        
        var tuple: Chars64 = (0, 0, 0, 0, 0, 0, 0, 0,
                              0, 0, 0, 0, 0, 0, 0, 0,
                              0, 0, 0, 0, 0, 0, 0, 0,
                              0, 0, 0, 0, 0, 0, 0, 0,
                              0, 0, 0, 0, 0, 0, 0, 0,
                              0, 0, 0, 0, 0, 0, 0, 0,
                              0, 0, 0, 0, 0, 0, 0, 0,
                              0, 0, 0, 0, 0, 0, 0, 0)
        
        withUnsafeMutableBytes(of: &tuple) { ptr in
            ptr.copyBytes(from: self.utf8.prefix(ptr.count))
        }
        
        return tuple
    }
}

private struct FileHeader
{
    let vertices: EntryInfo
    let indices: EntryInfo
    let surfaces: EntryInfo
    let textures: EntryInfo
}

private struct EntryInfo
{
    var offset: Int32
    var length: Int32
}

private struct FileSurface
{
    let firstIndex: Int32
    let indexCount: Int32
    let textureIndex: Int32
    let isLightmapped: Bool
}

