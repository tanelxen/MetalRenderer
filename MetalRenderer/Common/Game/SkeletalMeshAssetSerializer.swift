//
//  SkeletalMeshAssetSerializer.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 25.09.2023.
//

import Foundation

extension SkeletalMeshAsset
{
    static func load(from data: Data) -> SkeletalMeshAsset?
    {
        let bytes = NSData(data: data).bytes
        
        let pData = UnsafeRawPointer(bytes)
        let header = pData.load(as: FileHeader.self)
        
        let textures: [Chars64] = readChanks(for: header.textures, in: bytes)
        
        let surfaces: [FileSurface] = readChanks(for: header.surfaces, in: bytes)
        
        let sequences: [FileSequence] = readChanks(for: header.sequences, in: bytes)
        
        let rotations: [float3] = readChanks(for: header.bonerotations, in: bytes)
        let positions: [float3] = readChanks(for: header.bonepositions, in: bytes)
        let bones: [Int32] = readChanks(for: header.bones, in: bytes)
        
        var asset = SkeletalMeshAsset()
        
        asset.name = charsToString(header.name)
        
        asset.textures = textures.map { charsToString($0) }
        
        asset.surfaces = surfaces.map {
            Surface(firstIndex: Int($0.firstIndex),
                    indexCount: Int($0.indexCount),
                    textureIndex: Int($0.textureIndex)
            )
        }
        
        asset.vertices = readChanks(for: header.vertices, in: bytes)
        asset.indices = readChanks(for: header.indices, in: bytes)
        
        asset.bones = bones
        
        let numBones = bones.count
        let bonesRotations = rotations.chunked(into: numBones)
        let bonesPositions = positions.chunked(into: numBones)
        
        asset.sequences = sequences.map {
            
            let firstFrame = Int($0.firstFrame)
            let numFrames = Int($0.numFrames)
            let range = firstFrame ..< (firstFrame + numFrames)
            
            let bonesRotationsPerFrame = Array(bonesRotations[range])
            let bonesPositionsPerFrame = Array(bonesPositions[range])
            
            let frames = zip(bonesRotationsPerFrame, bonesPositionsPerFrame)
                .map {
                    Frame(rotationPerBone: $0, positionPerBone: $1)
                }
            
            return Sequence(
                name: charsToString($0.name),
                frames: frames,
                fps: $0.fps,
                groundSpeed: $0.groundSpeed)
        }
        
        return asset
    }
    
    private static func readChanks<T>(for entry: EntryInfo, in bytes: UnsafeRawPointer) -> [T]
    {
        let count = Int(entry.length) / MemoryLayout<T>.stride
        return bytes.readItems(offset: Int(entry.offset), count: count)
    }
}

extension SkeletalMeshAsset
{
    func toData() -> Data
    {
        let texturesData = texturesData()
        let indicesData = indicesData()
        let verticesData = verticesData()
        let surfacesData = surfacesData()
        let sequencesData = sequencesData()
        let rotationsData = rotationsData()
        let positionsData = positionsData()
        let bonesData = bonesData()
        
        
        var offset = Int32(MemoryLayout<FileHeader>.stride)
        
        let texturesEntry = EntryInfo(offset: offset, length: Int32(texturesData.count))
        offset += texturesEntry.length
        
        let surfacesEntry = EntryInfo(offset: offset, length: Int32(surfacesData.count))
        offset += surfacesEntry.length
        
        let verticesEntry = EntryInfo(offset: offset, length: Int32(verticesData.count))
        offset += verticesEntry.length
        
        let indicesEntry = EntryInfo(offset: offset, length: Int32(indicesData.count))
        offset += indicesEntry.length
        
        let sequencesEntry = EntryInfo(offset: offset, length: Int32(sequencesData.count))
        offset += sequencesEntry.length
        
        let rotationsEntry = EntryInfo(offset: offset, length: Int32(rotationsData.count))
        offset += rotationsEntry.length
        
        let positionsEntry = EntryInfo(offset: offset, length: Int32(positionsData.count))
        offset += positionsEntry.length
        
        let bonesEntry = EntryInfo(offset: offset, length: Int32(bonesData.count))
        offset += bonesEntry.length
        
        var header = FileHeader(
            name: name.asTuple64CChars,
            textures: texturesEntry,
            surfaces: surfacesEntry,
            vertices: verticesEntry,
            indices: indicesEntry,
            sequences: sequencesEntry,
            bonerotations: rotationsEntry,
            bonepositions: positionsEntry,
            bones: bonesEntry
        )
        
        var data = Data(bytes: &header, count: MemoryLayout<FileHeader>.stride)
        
        data.append(texturesData)
        data.append(surfacesData)
        data.append(verticesData)
        data.append(indicesData)
        data.append(sequencesData)
        data.append(rotationsData)
        data.append(positionsData)
        data.append(bonesData)
        
        return data
    }
    
    func saveToFolder(_ folder: URL)
    {
        let data = toData()
        
        do
        {
            let url = folder.appendingPathComponent("data.bin")
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
                textureIndex: Int32(surface.textureIndex)
            )
            
            let data = Data(bytes: &fileSurface, count: MemoryLayout<FileSurface>.stride)
            surfacesData.append(data)
        }
        
        return surfacesData
    }
    
    private func sequencesData() -> Data
    {
        var sequencesData = Data()
        
        var offset = 0
        
        for sequence in sequences
        {
            var fileSequence = FileSequence(
                name: sequence.name.asTuple64CChars,
                firstFrame: Int32(offset),
                numFrames: Int32(sequence.frames.count),
                fps: sequence.fps,
                groundSpeed: sequence.groundSpeed
            )
            
            offset += sequence.frames.count
            
            let data = Data(bytes: &fileSequence, count: MemoryLayout<FileSequence>.stride)
            sequencesData.append(data)
        }
        
        return sequencesData
    }
    
    private func rotationsData() -> Data
    {
        var rotationsData = Data()
        
        let frames = sequences.flatMap({ $0.frames })
        let rotations = frames.flatMap({ $0.rotationPerBone }) // size = framesNum x bonesNum
        
        for vector in rotations
        {
            var source = vector
            let data = Data(bytes: &source, count: MemoryLayout<float3>.stride)
            rotationsData.append(data)
        }
        
        return rotationsData
    }
    
    private func positionsData() -> Data
    {
        var positionsData = Data()
        
        let frames = sequences.flatMap({ $0.frames })
        let positions = frames.flatMap({ $0.positionPerBone }) // size = framesNum x bonesNum
        
        for vector in positions
        {
            var source = vector
            let data = Data(bytes: &source, count: MemoryLayout<float3>.stride)
            positionsData.append(data)
        }
        
        return positionsData
    }
    
    private func bonesData() -> Data
    {
        var bonesData = Data()
        
        for parent in bones
        {
            var source = parent
            let data = Data(bytes: &source, count: MemoryLayout<Int32>.stride)
            bonesData.append(data)
        }
        
        return bonesData
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
    let name: Chars64
    
    let textures: EntryInfo
    
    let surfaces: EntryInfo
    let vertices: EntryInfo
    let indices: EntryInfo
    
    let sequences: EntryInfo
    let bonerotations: EntryInfo
    let bonepositions: EntryInfo
    let bones: EntryInfo
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
}

private struct FileSequence
{
    let name: Chars64
    let firstFrame: Int32
    let numFrames: Int32
    let fps: Float
    let groundSpeed: Float
}
