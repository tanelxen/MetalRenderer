//
//  GoldSrcMDL.swift
//  Half-Life MDL
//
//  Created by Fedor Artemenkov on 15.02.2022.
//

import SequencesEncoder
import Foundation
import simd

public struct MeshVertex
{
    public let position: SIMD3<Float> // позиция вершины до применения матрицы
    public let texCoord: SIMD2<Float>
    public let boneIndex: Int  // индекс матрицы в массиве sequences.frames.bonetransforms
}

public struct Mesh
{
    public let vertexBuffer: [MeshVertex]
    public let indexBuffer: [Int]
    public let textureIndex: Int
}

public struct Texture
{
    public let name: String
    public let data: [UInt8]
    public let width: Int
    public let height: Int
}

public struct Frame
{
    public let bonetransforms: [matrix_float4x4]
}

public struct Sequence
{
    public let name: String
    public let frames: [Frame]
    public let fps: Float
    public let groundSpeed: Float
}

public struct ValveModel
{
    public var modelName = ""
    public var meshes: [Mesh] = []
    public var textures: [Texture] = []
    public var sequences: [Sequence] = []
}

public class GoldSrcMDL
{
    public var valveModel: ValveModel {
        ValveModel(modelName: self.modelName,
                   meshes: self.meshes,
                   textures: self.textures,
                   sequences: self.sequences)
    }
    
    private var modelName = ""
    private var meshes: [Mesh] = []
    private var textures: [Texture] = []
    
    private var sequences: [Sequence] = []
    
    private var buffer: BinaryReader
    
    private var mdlHeader: studiohdr_t!
    
    private var mdlTextures: [mstudiotexture_t] = []
    private var mdlSkinrefs: [Int16] = []
    
    private var mdlBodyparts: [mstudiobodyparts_t] = []
    private var mdlModels: [mstudiomodel_t] = []
    
//    private var bonetransforms: [matrix_float4x4] = []
    
    private var mdlSequences: [mstudioseqdesc_t] = []
    private var mdlSeqGroups: [mstudioseqgroup_t] = []
    private var mdlAnimations: [[mstudioanim_t]] = []
    private var mdlBones: [mstudiobone_t] = []
    
    private let bytes: UnsafeRawPointer
    
    private var seContext: UnsafeMutableRawPointer?
    
    public init(data: Data)
    {
        self.bytes = (data as NSData).bytes
        buffer = BinaryReader(data: data)
        
        readHeader()
        readTextures()
        
        mdlSeqGroups = buffer.readItems(offset: mdlHeader.seqgroupindex, count: mdlHeader.numseqgroups)
        
        readSequences()
        
        mdlBones = buffer.readItems(offset: mdlHeader.boneindex, count: mdlHeader.numbones)
        
        seContext = SequencesEncoder.createContext(bytes)
        setupBones()
        
        readBodyparts()
        
        SequencesEncoder.clearContext(seContext)
    }
    
    private func readHeader()
    {
        let pData = UnsafeMutableRawPointer(mutating: self.bytes)
        self.mdlHeader = pData.load(as: studiohdr_t.self)
        
        modelName = charsToString(mdlHeader.name)
    }
    
    private func readTextures()
    {
        let offset = Int(mdlHeader.textureindex)
        let count = Int(mdlHeader.numtextures)
        
        mdlTextures = buffer.readItems(offset: offset, count: count)
        textures = mdlTextures.map( { self.readTextureData($0) })
        
        if count > 0
        {
            let skin_offset = Int(mdlHeader.skinindex)
            let skin_count = Int(mdlHeader.numskinref)
            
            mdlSkinrefs = buffer.readItems(offset: skin_offset, count: skin_count)
        }
    }
    
    private func readTextureData(_ textureInfo: mstudiotexture_t) -> Texture
    {
        let offset = Int(textureInfo.index)
        let count: Int = Int(textureInfo.width * textureInfo.height)

        let textureData: [UInt8] = buffer.readItems(offset: Int(textureInfo.index), count: count)
        
        let RGB_SIZE = 3
        let RGBA_SIZE = 4
        
        // Total size of a palette, in bytes (RGB8)
        let PALETTE_SIZE = 256 * RGB_SIZE

        // Palette of colors
        let palette: [UInt8] = buffer.readItems(offset: offset + count, count: PALETTE_SIZE)

        // Create new image buffer
        var imageBuffer: [UInt8] = Array.init(repeating: 0, count: count * RGBA_SIZE)
        
        // Parsing indexed color: every item in texture data is index of color in colors palette
        for i in 0 ..< count
        {
            let item = textureData[i]

            let paletteOffset = Int(item) * RGB_SIZE
            let pixelOffset = i * RGBA_SIZE

            // Just applying to texture image data
            imageBuffer[pixelOffset + 0] = palette[paletteOffset + 0] // red
            imageBuffer[pixelOffset + 1] = palette[paletteOffset + 1] // green
            imageBuffer[pixelOffset + 2] = palette[paletteOffset + 2] // blue
            imageBuffer[pixelOffset + 3] = 255 // alpha
        }
        
        return Texture(name: charsToString(textureInfo.name),
                       data: imageBuffer,
                       width: Int(textureInfo.width),
                       height: Int(textureInfo.height))
    }
    
    private func readBodyparts()
    {
        let offset = Int(mdlHeader.bodypartindex)
        let count = Int(mdlHeader.numbodyparts)
        
        mdlBodyparts = buffer.readItems(offset: offset, count: count)
        
        for bodypart in mdlBodyparts
        {
            let models_offset = Int(bodypart.modelindex)
            let num_models = Int(bodypart.nummodels)
            
            let bodypart_models: [mstudiomodel_t] = buffer.readItems(offset: models_offset, count: num_models)
            
            for model in bodypart_models
            {
                let verts_offset = Int(model.vertindex)
                let num_verts = Int(model.numverts)
                let verts: [Float32] = buffer.readItems(offset: verts_offset, count: num_verts * 3)
                
                let mesh_offset = Int(model.meshindex)
                let num_mesh = Int(model.nummesh)
                let meshes: [mstudiomesh_t] = buffer.readItems(offset: mesh_offset, count: num_mesh)
                
                let vert_info_offset = Int(model.vertinfoindex)
                let num_vert_info = Int(model.numverts)
                let vert_info: [UInt8] = buffer.readItems(offset: vert_info_offset, count: num_vert_info)
                
                for mesh in meshes
                {
                    let tris_offset = Int(mesh.triindex)
                    let tris_count = Int(floor(Double(mdlHeader.length - mesh.triindex) / 2))
                    let tris: [Int16] = buffer.readItems(offset: tris_offset, count: tris_count)
                    
                    var textureIndex: Int?
                    
                    if mesh.skinref < mdlSkinrefs.count
                    {
                        textureIndex = Int(self.mdlSkinrefs[Int(mesh.skinref)])
                    }
                    
                    let mesh = readMesh(trianglesBuffer: tris, verticesBuffer: verts, textureIndex: textureIndex, bones: vert_info)
                    self.meshes.append(mesh)
                }
            }
        }
    }
    
    private func readMesh(trianglesBuffer: [Int16], verticesBuffer: [Float32], textureIndex: Int?, bones: [UInt8]) -> Mesh
    {
        var texture: mstudiotexture_t?
        
        if let index = textureIndex, index < mdlTextures.count
        {
            texture = mdlTextures[index]
        }
        
        let textureWidth: Float = Float(texture?.width ?? 64)
        let textureHeight: Float = Float(texture?.height ?? 64)
        
        // Current position in buffer
        var trisPos = 0
        
        struct vert_t
        {
            let pos: float3
            let uv: float2
            let vindex: Int
        }
        
        enum TrianglesType
        {
            case TRIANGLE_FAN
            case TRIANGLE_STRIP
        }
        
        var verticesData: [vert_t] = []
        var indicesData: [Int] = []

        // Processing triangle series
        while trianglesBuffer[trisPos] != 0
        {
            // Detecting triangle series type
            let trianglesType: TrianglesType = trianglesBuffer[trisPos] < 0 ? .TRIANGLE_FAN : .TRIANGLE_STRIP

            // Starting vertex for triangle fan
            var startVertIndex: Int? = nil

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
                    pos: float3(
                        verticesBuffer[vert + 0],
                        verticesBuffer[vert + 1],
                        verticesBuffer[vert + 2]),
                    uv: float2(
                        Float(trianglesBuffer[trisPos + 2]) / textureWidth,
                        Float(trianglesBuffer[trisPos + 3]) / textureHeight),
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
                            indicesData.append(contentsOf:
                                                    [
                                                        indicesData[indicesData.count - 3],   // previously first one
                                                        indicesData[indicesData.count - 1]    // last one
                                                    ]
                            )
                        }
                        else
                        {
                            // odd
                            indicesData.append(contentsOf:
                                                    [
                                                        indicesData[indicesData.count - 1],   // last one
                                                        indicesData[indicesData.count - 2]    // second to last
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
                    if startVertIndex == nil
                    {
                        startVertIndex = verticesData.count
                    }

                    if j > 2
                    {
                        indicesData.append(contentsOf:
                                                [
                                                    startVertIndex!,
                                                    indicesData[indicesData.count - 1]
                                                ]
                        )
                    }
                }

                // New one
                indicesData.append(verticesData.count)
                verticesData.append(vertexData)
            }
        }
        
        // Number of vertices for generating buffer
        let vertNumber = verticesData.count
        
        var meshVerts: [MeshVertex] = []

        for i in 0 ..< vertNumber
        {
//            let transformed_pos = applyBoneTransforms(position: verticesData[i].pos,
//                                                      vertIndex: verticesData[i].vindex,
//                                                      vertBoneBuffer: bones,
//                                                      boneTransforms: bonetransforms)
            
            let vertIndex = verticesData[i].vindex
            let boneIndex = Int(bones[vertIndex])
            
            meshVerts.append(
                MeshVertex(
                    position: verticesData[i].pos,
                    texCoord: verticesData[i].uv,
                    boneIndex: boneIndex
                )
            )
        }
        
        return Mesh(vertexBuffer: meshVerts,
                    indexBuffer: indicesData,
                    textureIndex: textureIndex ?? -1)
    }
    
    private func applyBoneTransforms(position: float3, vertIndex: Int, vertBoneBuffer: [UInt8], boneTransforms: [matrix_float4x4]) -> float3
    {
        let boneIndex = Int(vertBoneBuffer[vertIndex])
        let transform = boneTransforms[boneIndex]

        return transform * position
    }
    
    private func readSequences()
    {
        self.mdlSequences = buffer.readItems(offset: mdlHeader.seqindex, count: mdlHeader.numseq)
        
        for sequence in mdlSequences
        {
            let anims: [mstudioanim_t] = buffer.readItems(offset: sequence.animindex, count: mdlHeader.numbones)
            self.mdlAnimations.append(anims)
        }
    }
    
    private func setupBones()
    {
        for sequenceIndex in 0 ..< mdlSequences.count
        {
            let fps = mdlSequences[sequenceIndex].fps
            let numframes = mdlSequences[sequenceIndex].numframes

            var frames: [Frame] = []

            for frameIndex in 0 ..< mdlSequences[sequenceIndex].numframes
            {
                let bonetransforms = calcRotations(sequenceIndex: sequenceIndex, frame: Int(frameIndex))
                let frame = Frame(bonetransforms: bonetransforms)

                frames.append(frame)
            }
            
            let label = mdlSequences[sequenceIndex].label
            let name = charsToString(label)
            
            let movement = mdlSequences[sequenceIndex].linearmovement
            var groundSpeed = sqrt(movement.x * movement.x + movement.y * movement.y + movement.z * movement.z)
            groundSpeed = groundSpeed * fps / (Float(numframes) - 1)

            let sequence = Sequence(name: name, frames: frames, fps: fps, groundSpeed: groundSpeed)
            sequences.append(sequence)
        }
    }
    
    private func calcRotations(sequenceIndex: Int, frame: Int) -> [matrix_float4x4]
    {
        var boneQuaternions: [simd_quatf] = []
        var bonePositions: [float3] = []
        
        SequencesEncoder.calcRotations(Int32(sequenceIndex), Int32(frame), seContext);
        
        for boneIndex in 0 ..< mdlBones.count
        {
            var quat = Quaternion()
            SequencesEncoder.getBoneQuatertion(Int32(boneIndex), &quat, seContext)
            
            var vec = Vector3f()
            SequencesEncoder.getBonePosition(Int32(boneIndex), &vec, seContext)
            
            let q = simd_quatf(ix: quat.x, iy: quat.y, iz: quat.z, r: quat.w)
            let pos = float3(vec.x, vec.y, vec.z)
            
            boneQuaternions.append(q)
            bonePositions.append(pos)
        }

        return calcBoneTransforms(quaternions: boneQuaternions, positions: bonePositions, bones: mdlBones)
    }
    
    private func calcBoneTransforms(quaternions: [simd_quatf], positions: [float3], bones: [mstudiobone_t]) -> [matrix_float4x4]
    {
        var boneTransforms: [matrix_float4x4] = []
        
        for i in 0 ..< bones.count
        {
            var boneMatrix = matrix_float4x4.init(quaternions[i])

            boneMatrix[3].x = positions[i].x
            boneMatrix[3].y = positions[i].y
            boneMatrix[3].z = positions[i].z
            
            let parentIndex = Int(bones[i].parent)

            if parentIndex == -1
            {
                // Root bone
                boneTransforms.append(boneMatrix)
            }
            else
            {
                let parentMatrix = boneTransforms[parentIndex]
                let result = matrix_multiply(parentMatrix, boneMatrix)
                
                boneTransforms.append(result)
            }
        }
        
        return boneTransforms
    }
}

