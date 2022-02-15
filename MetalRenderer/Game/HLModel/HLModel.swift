//
//  HLModel.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 09.02.2022.
//

import Foundation

class HLModel
{
    private var buffer: BinaryReader
    
    private var header: studiohdr_t!
    
    private var textures: [mstudiotexture_t] = []
    private var skinref: [Int16] = []
    
    private var bodyparts: [mstudiobodyparts_t] = []
    private var models: [mstudiomodel_t] = []
    
    private var bonetransforms: [ms]
    
    var meshes: [Mesh] = []
    
    struct MeshVertex
    {
        let position: float3
        let texCoord: float2
    }
    
    struct Mesh
    {
        let vertexBuffer: [MeshVertex]
        let indexBuffer: [Int]
    }
    
    init(data: Data)
    {
        buffer = BinaryReader(data: data)
        
        readHeader()
        readTextures()
        readBodyparts()
    }
    
    private func readHeader()
    {
        header = decode(data: (buffer.data as NSData))
        
//        var nameBytes = header.name
//
//        let name: String = withUnsafePointer(to: &nameBytes) { ptr -> String in
//           return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
//        }
    }
    
    private func readTextures()
    {
        let offset = Int(header.textureindex)
        let count = Int(header.numtextures)
        
        textures = readItems(buffer.data, offset: offset, count: count)
        
        if count > 0
        {
            let skin_offset = Int(header.skinindex)
            let skin_count = Int(header.numskinref)
            
            skinref = readItems(buffer.data, offset: skin_offset, count: skin_count)
        }
    }
    
    private func readBodyparts()
    {
        let offset = Int(header.bodypartindex)
        let count = Int(header.numbodyparts)
        
        bodyparts = readItems(buffer.data, offset: offset, count: count)
        
        for bodypart in bodyparts
        {
            let models_offset = Int(bodypart.modelindex)
            let num_models = Int(bodypart.nummodels)
            
            let bodypart_models: [mstudiomodel_t] = readItems(buffer.data, offset: models_offset, count: num_models)
            
            for model in bodypart_models
            {
                let verts_offset = Int(model.vertindex)
                let num_verts = Int(model.numverts)
                let verts: [Float32] = readItems(buffer.data, offset: verts_offset, count: num_verts * 3)
                
                let mesh_offset = Int(model.meshindex)
                let num_mesh = Int(model.nummesh)
                let meshes: [mstudiomesh_t] = readItems(buffer.data, offset: mesh_offset, count: num_mesh)
                
                let vert_info_offset = Int(model.vertinfoindex)
                let num_vert_info = Int(model.numverts)
                let vert_info: [UInt8] = readItems(buffer.data, offset: vert_info_offset, count: num_vert_info)
                
                for mesh in meshes
                {
                    let tris_offset = Int(mesh.triindex)
                    let tris_count = Int(floor(Double(header.length - mesh.triindex) / 2))
                    let tris: [Int16] = readItems(buffer.data, offset: tris_offset, count: tris_count)
                    
                    let mesh = readMesh(trianglesBuffer: tris, verticesBuffer: verts, bones: vert_info)
                    self.meshes.append(mesh)
                }
            }
        }
    }
    
    private func readMesh(trianglesBuffer: [Int16], verticesBuffer: [Float32], bones: [UInt8]) -> Mesh
    {
        let textureWidth: Float = 1.0
        let textureHeight: Float = 1.0
        
        // Current position in buffer
        var trisPos = 0
        
        struct vert_t
        {
            let x, y, z: Float
            let u, v: Float
            let vindex: Int
        }
        
        enum TrianglesType
        {
            case TRIANGLE_FAN
            case TRIANGLE_STRIP
        }
        
        var verticesData: [vert_t] = []

        // Processing triangle series
        while trianglesBuffer[trisPos] != 0
        {
            // Detecting triangle series type
            let trianglesType: TrianglesType = trianglesBuffer[trisPos] < 0 ? .TRIANGLE_FAN : .TRIANGLE_STRIP

            // Starting vertex for triangle fan
            var startVert: vert_t? = nil

            // Number of following triangles
            let trianglesNum = abs(trianglesBuffer[trisPos])

            // This index is no longer needed,
            // we proceed to the following
            trisPos += 1

            // For counting we will make steps for 4 array items:
            // 0 — index of the vertex origin in vertices buffer
            // 1 — index of the normal
            // 2 — first uv coordinate
            // 3 — second uv coordinate
            for j in 0 ..< trianglesNum
            {
                let vertIndex = Int(trianglesBuffer[trisPos])
                let vert = Int(trianglesBuffer[trisPos]) * 3
//                let normal = Int(trianglesBuffer[trisPos + 1])
                
                // Vertex data
                let vertexData = vert_t(
                    x: verticesBuffer[vert + 0],
                    y: verticesBuffer[vert + 1],
                    z: verticesBuffer[vert + 2],
                    u: Float(trianglesBuffer[trisPos + 2]) / textureWidth,
                    v: 1.0 - Float(trianglesBuffer[trisPos + 3]) / textureHeight,
                    vindex: vertIndex
                )
                
                trisPos += 4

                // Unpacking triangle strip. Each next vertex, beginning with the third,
                // forms a triangle with the last and the penultimate vertex.
                //       1 ________3 ________ 5
                //       ╱╲        ╱╲        ╱╲
                //     ╱    ╲    ╱    ╲    ╱    ╲
                //   ╱________╲╱________╲╱________╲
                // 0          2         4          6
                if trianglesType == .TRIANGLE_STRIP
                {
                    if j > 2
                    {
                        if j % 2 == 0
                        {
                            // even
                            verticesData.append(contentsOf:
                                                    [
                                                        verticesData[verticesData.count - 3],   // previously first one
                                                        verticesData[verticesData.count - 1]    // last one
                                                    ]
                            )
                        }
                        else
                        {
                            // odd
                            verticesData.append(contentsOf:
                                                    [
                                                        verticesData[verticesData.count - 1],   // last one
                                                        verticesData[verticesData.count - 2]    // second to last
                                                    ]
                            )
                        }
                    }
                }

                // Unpacking triangle fan. Each next vertex, beginning with the third,
                // forms a triangle with the last and first vertex.
                //       2 ____3 ____ 4
                //       ╱╲    |    ╱╲
                //     ╱    ╲  |  ╱    ╲
                //   ╱________╲|╱________╲
                // 1          0            5
                if trianglesType == .TRIANGLE_FAN
                {
                    if startVert == nil
                    {
                        startVert = vertexData
                    }

                    if j > 2
                    {
                        verticesData.append(contentsOf:
                                                [
                                                    startVert!,
                                                    verticesData[verticesData.count - 1]
                                                ]
                        )
                    }
                }

                // New one
                verticesData.append( vertexData )
            }
        }
        
        // Number of vertices for generating buffer
        let vertNumber = verticesData.count
        
        var meshVerts: [MeshVertex] = []
        var indices = Array.init(repeating: 0, count: verticesData.count)

        for i in 0 ..< vertNumber
        {
            meshVerts.append(
                MeshVertex(
                    position: float3(verticesData[i].x, verticesData[i].y, verticesData[i].z),
                    texCoord: float2(verticesData[i].u, verticesData[i].v)
                )
            )
            
            indices[i] = verticesData[i].vindex
        }
        
        return Mesh(vertexBuffer: meshVerts, indexBuffer: indices)
    }
    
    private func readItems<T>(_ data: Data, offset: Int, count: Int) -> Array<T>
    {
        let size = MemoryLayout<T>.size
        let range = offset ..< (offset + count * size)
        let subdata = data.subdata(in: range)
        
        return subdata.withUnsafeBytes {
            Array(UnsafeBufferPointer<T>(start: $0, count: count))
        }
    }
}
