//
//  GoldSrcMDL.swift
//  Half-Life MDL
//
//  Created by Fedor Artemenkov on 15.02.2022.
//

import SequencesEncoder
import Foundation
import simd

public class GoldSrcMDL
{
    public var valveModel: ValveModel {
        ValveModel(
            modelName: self.modelName,
            meshes: self.meshes,
            textures: self.textures,
            sequences: self.sequences,
            bones: mdlBones.map({ Int($0.parent) })
        )
    }
    
    var modelName = ""
    var meshes: [Mesh] = []
    var textures: [Texture] = []
    var sequences: [Sequence] = []
    
    var buffer: BinaryReader
    
    var mdlHeader: studiohdr_t!
    
    var mdlTextures: [mstudiotexture_t] = []
    var mdlSkinrefs: [Int16] = []
    
    var mdlBodyparts: [mstudiobodyparts_t] = []
    var mdlModels: [mstudiomodel_t] = []
    
    var mdlSequences: [mstudioseqdesc_t] = []
    var mdlSeqGroups: [mstudioseqgroup_t] = []
    var mdlAnimations: [[mstudioanim_t]] = []
    var mdlBones: [mstudiobone_t] = []
    
    let bytes: UnsafeRawPointer
    
    var seContext: UnsafeMutableRawPointer?
    
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
}

