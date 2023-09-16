//
//  Q3Map.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.02.2022.
//

import Foundation
import simd

public class Q3Map
{
    public var entities: Array<Dictionary<String, String>> = []
    public var vertices: Array<Q3Vertex> = []
    public var faces: Array<Q3Face> = []
    public var textures: Array<Q3Texture> = []
    public var lightmaps: Array<Q3Lightmap> = []
    public var planes: [Q3Plane] = []
    public var brushes: [Q3Brush] = []
    public var brushSides: [Q3BrushSide] = []
    public var nodes: [Q3Node] = []
    public var leafs: [Q3Leaf] = []
    public var leaffaces: [Int32] = []
    public var leafbrushes: [Int32] = []
    
    private var buffer: BinaryReader
    private var directoryEntries: Array<Q3DirectoryEntry> = []
    private var meshverts: Array<UInt32> = []
    
    public var models: [Q3Model] = []
    public var lightgrid: [Q3LightProbe] = []
    
    // Read the map data from an NSData buffer containing the bsp file
    public init(data: Data)
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
        
        models = readModels()
        lightgrid = readProbes()
    }
    
    private func readHeaders()
    {
        // Magic should always equal IBSP for Q3 maps
        let magic = buffer.getASCII(4)
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
    
    private func readEntities() -> Array<Dictionary<String, String>>
    {
        let chars = readLump(.entities, as: CChar.self)
        let entities = String(cString: chars)
        
        let parser = Q3EntityParser(entitiesString: entities)

        return parser.parse()
    }
    
    private func readTextures() -> Array<Q3Texture>
    {
        struct Texture
        {
            let name: String
            let surfaceFlags: Int32
            let contentFlags: Int32
        }

        return readEntry(Lumps.textures.rawValue, length: 72) { buffer in

            let name = buffer.getASCII(64)
            let flags = buffer.getInt32()
            let content = buffer.getInt32()

            return Q3Texture(texureName: name,
                      surfaceFlags: flags,
                      contentFlags: content)
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
                
                var simd: float3 {
                    float3(x, y, z)
                }
            }
            
            struct vec2
            {
                let x, y: Float32
                
                var simd: float2 {
                    float2(x, y)
                }
            }
            
            struct color
            {
                let r, g, b, a: UInt8
                
                var simd: float3 {
                    float3(Float(r)/255, Float(g)/255, Float(b)/255)
                }
            }
        }
        
        let vertices = readLump(.vertexes, as: Vertex.self).map {
            
            Q3Vertex(
                position: $0.position.simd,
                textureCoord: $0.textureCoord.simd,
                lightmapCoord: $0.lightmapCoord.simd,
                color: $0.color.simd
            )
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
        
        let planes = readLump(.planes, as: Plane.self).map { p -> Q3Plane in
            
            let normal = float3(p.normal.x, p.normal.y, p.normal.z)
            return Q3Plane(normal: normal, distance: p.dist)
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
                   child: [Int($0.front), Int($0.back)],
                   mins: float3(Float($0.mins.x), Float($0.mins.y), Float($0.mins.z)),
                   maxs: float3(Float($0.maxs.x), Float($0.maxs.y), Float($0.maxs.z)))
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
                   mins: float3(Float($0.mins.x), Float($0.mins.y), Float($0.mins.z)),
                   maxs: float3(Float($0.maxs.x), Float($0.maxs.y), Float($0.maxs.z)),
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
    
    private func readFaces() -> Array<Q3Face>
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
                    vertexIndices: polygonFace.indices,
                    type: type
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
                    vertexIndices: indices,
                    type: type
                )
            }
            
            return nil
        }
    }
    
    private func readModels() -> [Q3Model]
    {
        struct Model
        {
            let mins: vec3
            let maxs: vec3
            let face: Int32
            let n_faces: Int32
            let brush: Int32
            let n_brushes: Int32
            
            struct vec3
            {
                let x, y, z: Float32
                
                var simd: float3 {
                    float3(x, y, z)
                }
            }
        }
        
        let models = readLump(.models, as: Model.self).map {
            Q3Model(
                mins: $0.mins.simd,
                maxs: $0.maxs.simd,
                face: Int($0.face),
                n_faces: Int($0.n_faces),
                brush: Int($0.brush),
                n_brushes: Int($0.n_brushes)
            )
        }

        return models
    }
    
    private func readProbes() -> [Q3LightProbe]
    {
        struct Probe
        {
            let ambient: color
            let directional: color
            let phi: UInt8
            let theta: UInt8
            
            struct color
            {
                let r, g, b: UInt8
                
                var simd: float3 {
                    float3(Float(r)/255, Float(g)/255, Float(b)/255)
                }
            }
        }
        
        let probes = readLump(.lightvols, as: Probe.self).map {
            
            let phi = (Float($0.phi) - 128)/255 * 180
            let theta = Float($0.theta)/255 * 360
            
            let dir = float3(
                x: sin(theta) * cos(phi),
                y: cos(theta) * cos(phi),
                z: sin(phi)
            )
            
            return Q3LightProbe(
                ambient: $0.ambient.simd,
                directional: $0.directional.simd,
                direction: normalize(dir)
            )
        }

        return probes
    }
    
    private func readEntry<T>(_ index: Int, length: Int, each: (BinaryReader) -> T?) -> Array<T>
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
        let count = length / MemoryLayout<T>.size
        
        let pointer = (buffer.data.bytes + offset).bindMemory(to: T.self, capacity: count)
        let buffer = UnsafeBufferPointer(start: pointer, count: count)
        
        return Array(buffer)
    }
}

extension Q3Map
{
    public func saveAsOBJ(url: URL)
    {
        FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
        
        let fileHandle = FileHandle(forWritingAtPath: url.path)!
        
        for vertex in vertices
        {
            let pos = vertex.position
            let str = "v \(pos.x) \(pos.z) \(-pos.y)\n"
            
            write(str, to: fileHandle)
        }
        
        for face in faces
        {
            if face.textureName == "noshader" { continue }
            if face.textureName.contains("sky") { continue }
//            if face.type == .mesh { continue }
            
            for poly in face.vertexIndices.chunked(into: 3)
            {
                let str = "f \(poly[0] + 1) \(poly[2] + 1) \(poly[1] + 1)\n"
                write(str, to: fileHandle)
            }
        }
    }
    
    private func write(_ string: String, to fileHandle: FileHandle)
    {
        fileHandle.seekToEndOfFile()
        
        if let data = string.data(using: .utf8)
        {
            fileHandle.write(data)
        }
    }
}

extension Data
{
    func subdata(in range: ClosedRange<Index>) -> Data
    {
        return subdata(in: range.lowerBound ..< range.upperBound + 1)
    }
}

extension Array
{
    func chunked(into size: Int) -> [[Element]]
    {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
