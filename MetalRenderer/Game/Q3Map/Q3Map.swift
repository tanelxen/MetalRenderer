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
    var textures: Array<Q3Texture> = []
    var lightmaps: Array<Q3Lightmap> = []
    
    var planes: [Q3Plane] = []
    var brushes: [Q3Brush] = []
    var brushSides: [Q3BrushSide] = []
    var nodes: [Q3Node] = []
    var leafs: [Q3Leaf] = []
    var leaffaces: [Int32] = []
    var leafbrushes: [Int32] = []
    
    fileprivate var buffer: BinaryReader
    fileprivate var directoryEntries: Array<Q3DirectoryEntry> = []
    fileprivate var meshverts: Array<UInt32> = []
    
    // Read the map data from an NSData buffer containing the bsp file
    init(data: Data)
    {
        buffer = BinaryReader(data: data)
        
        readHeaders()
        
        entities = readEntities()
        textures = readTextures()
        vertices = readVertices()
        planes = readPlanes()
        nodes = readNodes()
        leafs = readLeafs()
        leaffaces = readLump(.leaffaces, as: Int32.self)
        leafbrushes = readLump(.leafbrushes, as: Int32.self)
        brushes = readBrushes()
        brushSides = readBrushSides()
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
        let chars = readLump(.entities, as: CChar.self)
        let entities = String(cString: chars)
        
        let parser = Q3EntityParser(entitiesString: entities)

        return parser.parse()
    }
    
    fileprivate func readTextures() -> Array<Q3Texture>
    {
        return readEntry(Lumps.textures.rawValue, length: 72) { buffer in
            
            Q3Texture(texureName: buffer.getASCIIUntilNull(64),
                      surfaceFlags: buffer.getInt32(),
                      contentFlags: buffer.getInt32())
        }
    }
    
    private func readVertices() -> Array<Q3Vertex>
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
        
        let vertices = readLump(.vertexes, as: Vertex.self).map {
            Q3Vertex(position: float4($0.position.x, $0.position.z, -$0.position.y, 1.0),
                     normal: float4($0.normal.x, $0.normal.z, -$0.normal.y, 0.0),
                     color: float4(Float($0.color.r) / 255, Float($0.color.g) / 255, Float($0.color.b) / 255, Float($0.color.a) / 255),
                     textureCoord: float2($0.textureCoord.x, $0.textureCoord.y),
                     lightmapCoord: float2($0.lightmapCoord.x, $0.lightmapCoord.y))
        }

        return vertices
    }
    
    private func readMeshverts() -> Array<UInt32>
    {
        return readEntry(11, length: 4) { buffer in
            return UInt32(buffer.getInt32())
        }
    }
    
    private func readPlanes() -> [Q3Plane]
    {
        struct Plane
        {
            let normal: vec3
            let dist: Float32
            
            struct vec3
            {
                let x, y, z: Float32
            }
        }
        
        let planes = readLump(.planes, as: Plane.self).map {
            Q3Plane(normal: float3($0.normal.x, $0.normal.z, -$0.normal.y),
                    distance: $0.dist)
        }

        return planes
    }
    
    private func readNodes() -> [Q3Node]
    {
        struct Node
        {
            let plane: Int32
            let front: Int32
            let back: Int32
            let mins: vec3
            let maxs: vec3
            
            struct vec3
            {
                let x, y, z: Int32
            }
        }
        
        let nodes = readLump(.nodes, as: Node.self).map {
            Q3Node(plane: Int($0.plane),
                   front: Int($0.front),
                   back: Int($0.back),
                   mins: float3(Float($0.mins.x), Float($0.mins.z), -Float($0.mins.y)),
                   maxs: float3(Float($0.maxs.x), Float($0.maxs.z), -Float($0.maxs.y)))
        }

        return nodes
    }
    
    private func readLeafs() -> [Q3Leaf]
    {
        struct Leaf
        {
            let cluster: Int32
            let area: Int32
            let mins: vec3
            let maxs: vec3
            let leafface: Int32
            let n_leaffaces: Int32
            let leafbrush: Int32
            let n_leafbrushes: Int32
            
            struct vec3
            {
                let x, y, z: Int32
            }
        }
        
        let leafs = readLump(.leafs, as: Leaf.self).map {
            Q3Leaf(cluster: Int($0.cluster),
                   area: Int($0.area),
                   mins: float3(Float($0.mins.x), Float($0.mins.z), -Float($0.mins.y)),
                   maxs: float3(Float($0.maxs.x), Float($0.maxs.z), -Float($0.maxs.y)),
                   leafface: Int($0.leafface),
                   n_leaffaces: Int($0.n_leaffaces),
                   leafbrush: Int($0.leafbrush),
                   n_leafbrushes: Int($0.n_leafbrushes))
        }

        return leafs
    }
    
    private func readBrushes() -> [Q3Brush]
    {
        struct Brush
        {
            let brushside: Int32
            let n_brushsides: Int32
            let texture: Int32
        }
        
        let brushes = readLump(.brushes, as: Brush.self).map {
            Q3Brush(brushside: Int($0.brushside),
                    numBrushsides: Int($0.n_brushsides),
                    texture: Int($0.texture))
        }

        return brushes
    }
    
    private func readBrushSides() -> [Q3BrushSide]
    {
        struct BrushSide
        {
            let plane: Int32
            let texture: Int32
        }
        
        let brushes = readLump(.brushsides, as: BrushSide.self).map {
            Q3BrushSide(plane: Int($0.plane), texture: Int($0.texture))
        }

        return brushes
    }
    
    private func readLightmaps() -> Array<Q3Lightmap>
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
            
            let textureName = self.textures[textureIndex].texureName
            
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
    
    private func readLump<T>(_ lump: Lumps, as type: T.Type) -> Array<T>
    {
        let entry = directoryEntries[lump.rawValue]
        
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
    
//    fileprivate func swizzle(_ v: float3) -> float3
//    {
//        return float3(v.x, v.z, -v.y)
//    }
//    
//    fileprivate func swizzle(_ v: float4) -> float4
//    {
//        return float4(v.x, v.z, -v.y, 1)
//    }
}

extension Data {
    func subdata(in range: ClosedRange<Index>) -> Data {
        return subdata(in: range.lowerBound ..< range.upperBound + 1)
    }
}
