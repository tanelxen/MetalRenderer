//
//  Q3Map.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.02.2022.
//

import Foundation

private struct Q3DirectoryEntry
{
    var offset: Int32 = 0
    var length: Int32 = 0
}

private struct Q3PolygonFace
{
    let indices: Array<UInt32>
    
    init(meshverts: [UInt32], firstVertex: Int, firstMeshvert: Int, meshvertCount: Int)
    {
        let meshvertIndices = firstMeshvert..<(firstMeshvert + meshvertCount)
        indices = meshvertIndices.map { meshverts[$0] + UInt32(firstVertex) }
    }
}

private struct Q3PatchFace
{
    var vertices: Array<Q3Vertex> = []
    fileprivate var indices: Array<UInt32> = []
    
    init(vertices: Array<Q3Vertex>, firstVertex: Int, vertexCount: Int, size: (Int, Int))
    {
        let numPatchesX = ((size.0) - 1) / 2
        let numPatchesY = ((size.1) - 1) / 2
        let numPatches = numPatchesX * numPatchesY
        
        for patchNumber in 0 ..< numPatches
        {
            // Find the x & y of this patch in the grid
            let xStep = patchNumber % numPatchesX
            let yStep = patchNumber / numPatchesX
            
            // Initialise the vertex grid
            var vertexGrid: [[Q3Vertex]] = Array(
                repeating: Array(
                    repeating: Q3Vertex(),
                    count: Int(size.1)
                ),
                count: Int(size.0)
            )
            
            var gridX = 0
            var gridY = 0
            
            for index in firstVertex..<(firstVertex + vertexCount)
            {
                // Place the vertices from the face in the vertex grid
                vertexGrid[gridX][gridY] = vertices[index]
                
                gridX += 1
                
                if gridX == Int(size.0) {
                    gridX = 0
                    gridY += 1
                }
            }
            
            let vi = 2 * xStep
            let vj = 2 * yStep
            var controlVertices: [Q3Vertex] = []
            
            for i in 0..<3 {
                for j in 0..<3 {
                    controlVertices.append(vertexGrid[Int(vi + j)][Int(vj + i)])
                }
            }
            
            let bezier = Bezier(controls: controlVertices)
            
            self.indices.append(
                contentsOf: bezier.indices.map { i in i + UInt32(self.vertices.count) }
            )
            
            self.vertices.append(contentsOf: bezier.vertices)
        }
    }
    
    func offsetIndices(_ offset: UInt32) -> Array<UInt32>
    {
        return self.indices.map { $0 + offset }
    }
}


class Q3Map
{
    var entities: Array<Dictionary<String, String>> = []
    var vertices: Array<Q3Vertex> = []
    var faces: Array<Q3Face> = []
    var textureNames: Array<String> = []
    var lightmaps: Array<Q3Lightmap> = []
    
    fileprivate var buffer: BinaryReader
    fileprivate var directoryEntries: Array<Q3DirectoryEntry> = []
    fileprivate var meshverts: Array<UInt32> = []
    
    // Read the map data from an NSData buffer containing the bsp file
    init(data: Data)
    {
        buffer = BinaryReader(data: data)
        
        readHeaders()
        
        entities = readEntities()
        textureNames = readTextureNames()
        vertices = readVertices()
        meshverts = readMeshverts()
        lightmaps = readLightmaps()
        faces = readFaces()
    }
    
    fileprivate func readHeaders()
    {
        // Magic should always equal IBSP for Q3 maps
        let magic = buffer.getASCII(4)!
        assert(magic == "IBSP", "Magic must be equal to \"IBSP\"")
        
        // Version should always equal 0x2e for Q3 maps
        let version = buffer.getInt32()
        assert(version == 0x2e, "Version must be equal to 0x2e")
        
        // Directory entries define the position and length of a section
        for _ in 0 ..< 17
        {
            let entry = Q3DirectoryEntry(offset: buffer.getInt32(), length: buffer.getInt32())
            directoryEntries.append(entry)
        }
    }
    
    fileprivate func readEntities() -> Array<Dictionary<String, String>>
    {
        let entry = directoryEntries[0]

        buffer.jump(Int(entry.offset))

        let entities = buffer.getASCII(Int(entry.length))
        let parser = Q3EntityParser(entitiesString: entities! as String)

        return parser.parse()
    }
    
    fileprivate func readTextureNames() -> Array<String>
    {
        return readEntry(1, length: 72) { buffer in
            return buffer.getASCIIUntilNull(64)
        }
    }
    
    fileprivate func readVertices() -> Array<Q3Vertex>
    {
        struct Vertex
        {
            let position: vec3
            let textureCoord: vec2
            let lightmapCoord: vec2
            let normal: vec3
            let color: color
            
            struct vec3
            {
                let x, y, z: Float32
            }
            
            struct vec2
            {
                let x, y: Float32
            }
            
            struct color
            {
                let r, g, b, a: UInt8
            }
        }
        
        let vertices = readLump(at: 10, type: Vertex.self).map {
            Q3Vertex(position: float4($0.position.x, $0.position.z, -$0.position.y, 1.0),
                     normal: float4($0.normal.x, $0.normal.z, -$0.normal.y, 0.0),
                     color: float4(Float($0.color.r) / 255, Float($0.color.g) / 255, Float($0.color.b) / 255, Float($0.color.a) / 255),
                     textureCoord: float2($0.textureCoord.x, $0.textureCoord.y),
                     lightmapCoord: float2($0.lightmapCoord.x, $0.lightmapCoord.y))
        }

        return vertices
    }
    
    fileprivate func readMeshverts() -> Array<UInt32>
    {
        return readEntry(11, length: 4) { buffer in
            return UInt32(buffer.getInt32())
        }
    }
    
    
    fileprivate func readLightmaps() -> Array<Q3Lightmap>
    {
        return readEntry(14, length: 128 * 128 * 3) { buffer in
            var lm: Q3Lightmap = []
            
            for _ in 0..<(128 * 128) {
                lm.append((buffer.getUInt8(), buffer.getUInt8(), buffer.getUInt8(), 255))
            }
            
            return lm
        }
    }
    
    fileprivate func readFaces() -> Array<Q3Face>
    {
        return readEntry(13, length: 104) { buffer in
            
            let textureIndex = Int(buffer.getInt32())
            buffer.skip(4) // effect
            let type = Q3FaceType(rawValue: Int(buffer.getInt32()))!
            let firstVertex = Int(buffer.getInt32())
            let vertexCount = Int(buffer.getInt32())
            let firstMeshvert = Int(buffer.getInt32())
            let meshvertCount = Int(buffer.getInt32())
            let lightmapIndex = Int(buffer.getInt32())
            buffer.skip(64) // Extranious lightmap info
            let patchSizeX = Int(buffer.getInt32())
            let patchSizeY = Int(buffer.getInt32())
            
            let textureName = self.textureNames[textureIndex]
            
            if type == .polygon || type == .mesh
            {
                let polygonFace = Q3PolygonFace(
                    meshverts: self.meshverts,
                    firstVertex: firstVertex,
                    firstMeshvert: firstMeshvert,
                    meshvertCount: meshvertCount
                )
                
                return Q3Face(
                    textureName: textureName,
                    lightmapIndex: lightmapIndex,
                    vertexIndices: polygonFace.indices
                )
            }
            else if type == .patch
            {
                let patchFace = Q3PatchFace(
                    vertices: self.vertices,
                    firstVertex: firstVertex,
                    vertexCount: vertexCount,
                    size: (patchSizeX, patchSizeY)
                )

                // The indices for a patch will be for it's own vertices.
                // Offset them by the amount of vertices in the map, then add
                // the patch's own vertices to the list
                let indices = patchFace.offsetIndices(UInt32(self.vertices.count))
                self.vertices.append(contentsOf: patchFace.vertices)

                return Q3Face(
                    textureName: textureName,
                    lightmapIndex: lightmapIndex,
                    vertexIndices: indices
                )
            }
            
            return nil
        }
    }
    
    fileprivate func readEntry<T>(_ index: Int, length: Int, each: (BinaryReader) -> T?) -> Array<T>
    {
        let entry = directoryEntries[index]
        let itemCount = Int(entry.length) / length
        var accumulator: Array<T> = []
        
        for i in 0 ..< itemCount
        {
            buffer.jump(Int(entry.offset) + (i * length))
            
            if let value = each(buffer)
            {
                accumulator.append(value)
            }
        }
        
        return accumulator
    }
    
    private func readLump<T>(at index: Int, type: T.Type) -> Array<T>
    {
        let entry = directoryEntries[index]
        
        let offset = Int(entry.offset)
        let length = Int(entry.length)
        
        let itemsCount = Int(entry.length) / Int(MemoryLayout<T>.size)
        
        let range = offset ..< (offset + length)
        let lumpData = buffer.data.subdata(in: range)
        
        let arr: [T] = lumpData.withUnsafeBytes {
//            Array(UnsafeBufferPointer<UInt32>
            Array(UnsafeBufferPointer<T>(start: $0, count: itemsCount))
        }
        
        return arr
    }
    
    fileprivate func swizzle(_ v: float3) -> float3
    {
        return float3(v.x, v.z, -v.y)
    }
    
    fileprivate func swizzle(_ v: float4) -> float4
    {
        return float4(v.x, v.z, -v.y, 1)
    }
}

extension Data {
    func subdata(in range: ClosedRange<Index>) -> Data {
        return subdata(in: range.lowerBound ..< range.upperBound + 1)
    }
}
