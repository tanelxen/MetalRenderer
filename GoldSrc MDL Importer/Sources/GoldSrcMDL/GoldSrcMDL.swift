//
//  GoldSrcMDL.swift
//  Half-Life MDL
//
//  Created by Fedor Artemenkov on 15.02.2022.
//

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
    
    public init(data: Data)
    {
        self.bytes = (data as NSData).bytes
        buffer = BinaryReader(data: data)
        
        readHeader()
        readTextures()
        
        mdlSeqGroups = buffer.readItems(offset: mdlHeader.seqgroupindex, count: mdlHeader.numseqgroups)
        
        readSequences()
        
        mdlBones = buffer.readItems(offset: mdlHeader.boneindex, count: mdlHeader.numbones)
        
        setupBones()
        
        readBodyparts()
    }
    
    private func readHeader()
    {
        let pData = UnsafeMutableRawPointer(mutating: self.bytes)
        self.mdlHeader = pData.load(as: studiohdr_t.self)
        
        var nameBytes = mdlHeader.name

        modelName = withUnsafePointer(to: &nameBytes) { ptr -> String in
           return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
        }
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
        
        var nameBytes = textureInfo.name

        let name: String = withUnsafePointer(to: &nameBytes) { ptr -> String in
           return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
        }
        
        return Texture(name: name,
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
            var label = mdlSequences[sequenceIndex].label

            let name = withUnsafePointer(to: &label) { ptr -> String in
               return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
            }

            var frames: [Frame] = []

            for frameIndex in 0 ..< mdlSequences[sequenceIndex].numframes
            {
                let bonetransforms = calcRotations(sequenceIndex: sequenceIndex, frame: Int(frameIndex))
                let frame = Frame(bonetransforms: bonetransforms)

                frames.append(frame)
            }

            let sequence = Sequence(name: name, frames: frames)
            sequences.append(sequence)
        }
    }
    
    private func calcRotations(sequenceIndex: Int, frame: Int, s: Float = 0) -> [matrix_float4x4]
    {
        var boneQuaternions: [simd_quatf] = []
        var bonePositions: [float3] = []
        
        for boneIndex in 0 ..< mdlBones.count
        {
            let q = calcBoneQuaternion(frame: frame,
                                       bone: mdlBones[boneIndex],
                                       anim: mdlAnimations[sequenceIndex][boneIndex],
                                       sequenceIndex: sequenceIndex,
                                       boneIndex: boneIndex,
                                       s: s)
            
            let pos = calcBonePosition(frame: frame,
                                       s: s,
                                       bone: mdlBones[boneIndex],
                                       anim: mdlAnimations[sequenceIndex][boneIndex],
                                       animindex: UInt16(sequenceIndex))
            
            boneQuaternions.append(q)
            bonePositions.append(pos)
        }

        return calcBoneTransforms(quaternions: boneQuaternions, positions: bonePositions, bones: mdlBones)
    }
    
    private func calcBoneQuaternion(frame: Int, bone: mstudiobone_t, anim: mstudioanim_t, sequenceIndex: Int, boneIndex: Int, s: Float) -> simd_quatf
    {
        var angle1 = float3()
        var angle2 = float3()
        
        let animStructLength = MemoryLayout<mstudioanim_t>.size
        
        let bone_value = [bone.value.0, bone.value.1, bone.value.2,
                          bone.value.3, bone.value.4, bone.value.5]
        
        let bone_scale = [bone.scale.0, bone.scale.1, bone.scale.2,
                          bone.scale.3, bone.scale.4, bone.scale.5]
        
        let animOffset = [anim.offset.0, anim.offset.1, anim.offset.2,
                          anim.offset.3, anim.offset.4, anim.offset.5]
        
        let reader = BinaryReader(data: buffer.data)
        
        func getAnimValue(_ index: Int, axis: Int) -> AnimValue
        {
            let animationIndex = Int(mdlSequences[sequenceIndex].animindex) + boneIndex * animStructLength
            
            let offset = animationIndex + Int(animOffset[axis + 3]) + index * MemoryLayout<Int16>.size
            
            reader.position = offset
            let value = reader.getInt16()

            return AnimValue(value)
        }
        
        for axis in 0 ..< 3
        {
            if animOffset[axis + 3] == 0
            {
                // default
                angle1[axis] = bone_value[axis + 3]
                angle2[axis] = angle1[axis]
            }
            else
            {
                var i = 0
                var k = frame
                
                var animValue = getAnimValue(i, axis: axis)

                while animValue.total <= k
                {
                    k -= animValue.total
                    i += animValue.valid + 1
                    
                    animValue = getAnimValue(i, axis: axis)
                }
                
                let valid = animValue.valid
                let total = animValue.total
                
                // Bah, missing blend!
                if valid > k
                {
                    angle1[axis] = getAnimValue(i + k + 1, axis: axis).value

                    if valid > k + 1
                    {
                        angle2[axis] = getAnimValue(i + k + 2, axis: axis).value
                    }
                    else
                    {
                        if total > k + 1
                        {
                            angle2[axis] = angle1[axis]
                        }
                        else
                        {
                            angle2[axis] = getAnimValue(i + valid + 2, axis: axis).value
                        }
                    }
                }
                else
                {
                    angle1[axis] = getAnimValue(i + valid, axis: axis).value

                    if total > k + 1
                    {
                        angle2[axis] = angle1[axis]
                    }
                    else
                    {
                        angle2[axis] = getAnimValue(i + valid + 2, axis: axis).value
                    }
                }

                angle1[axis] = bone_value[axis + 3] + angle1[axis] * bone_scale[axis + 3]
                angle2[axis] = bone_value[axis + 3] + angle2[axis] * bone_scale[axis + 3]
            }
        }
        
        if angle1 == angle2
        {
            return anglesToQuaternion(angle1)
        }

        let q1 = anglesToQuaternion(angle1)
        let q2 = anglesToQuaternion(angle2)
        
        return simd_slerp(q1, q2, s)
    }
    
    private func calcBonePosition(frame: Int, s: Float, bone: mstudiobone_t, anim: mstudioanim_t, animindex: UInt16) -> float3
    {
        return float3(bone.value.0, bone.value.1, bone.value.2)
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

