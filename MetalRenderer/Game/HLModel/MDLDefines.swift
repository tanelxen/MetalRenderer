//
//  MDLDefines.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 15.02.2022.
//

import Foundation

extension HLModel
{
    struct studiohdr_t
    {
        let magic: (CChar, CChar, CChar, CChar)
        let version: Int32
        let name: Chars64
        let length: Int32
        
        let eyeposition: vec3
        let min: vec3
        let max: vec3
        let bbmin: vec3
        let bbmax: vec3

        let flags: Int32

        let numbones: Int32
        let boneindex: Int32

        let numbonecontrollers: Int32
        let bonecontrollerindex: Int32

        let numhitboxes: Int32
        let hitboxindex: Int32

        let numseq: Int32
        let seqindex: Int32

        let numseqgroups: Int32        // demand loaded sequences
        let seqgroupindex: Int32

        let numtextures: Int32       // raw textures
        let textureindex: Int32
        let texturedataindex: Int32

        let numskinref: Int32           // replaceable textures
        let numskinfamilies: Int32
        let skinindex: Int32

        let numbodyparts: Int32
        let bodypartindex: Int32

        let numattachments: Int32        // queryable attachable points
        let attachmentindex: Int32

        let soundtable: Int32
        let soundindex: Int32
        let soundgroups: Int32
        let soundgroupindex: Int32

        let numtransitions: Int32        // animation node to animation node transition graph
        let transitionindex: Int32
    }

    struct mstudiobodyparts_t
    {
        let name: Chars64
        let nummodels: Int32
        let base: Int32
        let modelindex: Int32 // index into models array
    }

    // skin info
    struct mstudiotexture_t
    {
        let name: Chars64
        let flags: Int32
        let width: Int32
        let height: Int32
        let index: Int32
    }

    struct mstudiomodel_t
    {
        let name: Chars64

        let type: Int32

        let boundingradius: Float32

        let nummesh: Int32
        let meshindex: Int32

        let numverts: Int32        // number of unique vertices
        let vertinfoindex: Int32    // vertex bone info
        let vertindex: Int32        // vertex vec3_t
        let numnorms: Int32        // number of unique surface normals
        let norminfoindex: Int32    // normal bone info
        let normindex: Int32        // normal vec3_t

        let numgroups: Int32        // deformation groups
        let groupindex: Int32
    }

    struct mstudiomesh_t
    {
        let numtris: Int32
        let triindex: Int32
        let skinref: Int32
        let numnorms: Int32   // per mesh normals
        let normindex: Int32  // normal vec3_t
    }
    
    struct mstudiobone_t
    {
        let name: Chars32
        let parent: Int32
        let flags: Int32
        let bonecontroller: (Int32, Int32, Int32, Int32, Int32, Int32)
        let value: (Float32, Float32, Float32, Float32, Float32, Float32)
        let scale: (Float32, Float32, Float32, Float32, Float32, Float32)
    }
    
    //
    // demand loaded sequence groups
    //
    struct mstudioseqgroup_t
    {
        let label: Chars32      // textual name
        let name: Chars64       // file name
        let cache: Int32        // was "cache"  - index pointer
        let data: Int32         // was "data" -  hack for group 0
    }
    
    // sequence descriptions
    struct mstudioseqdesc_t
    {
        let label: Chars32    // sequence label

        let fps: Float32        // frames per second
        let flags: Int32        // looping/non-looping flags

        let activity: Int32
        let actweight: Int32

        let numevents: Int32
        let eventindex: Int32

        let numframes: Int32    // number of frames per sequence

        let numpivots: Int32    // number of foot pivots
        let pivotindex: Int32

        let motiontype: Int32
        let motionbone: Int32
        let linearmovement: vec3
        let automoveposindex: Int32
        let automoveangleindex: Int32

        let bbmin: vec3        // per sequence bounding box
        let bbmax: vec3

        let numblends: Int32
        let animindex: Int32        // mstudioanim_t pointer relative to start of sequence group data
                                            // [blend][bone][X, Y, Z, XR, YR, ZR]

        let blendtype: (Int32, Int32)    // X, Y, Z, XR, YR, ZR
        let blendstart: (Float32, Float32)    // starting value
        let blendend: (Float32, Float32)    // ending value
        let blendparent: Int32

        let seqgroup: Int32        // sequence group for demand loading

        let entrynode: Int32        // transition node at entry
        let exitnode: Int32        // transition node at exit
        let nodeflags: Int32        // transition rules
        
        let nextseq: Int32        // auto advancing sequences
    }
    
    struct mstudioanim_t
    {
        let offset: (UInt16, UInt16, UInt16, UInt16, UInt16, UInt16)
    }
    
    // animation frames
    struct mstudioanimvalue_t
    {
        let valid: UInt8
        let total: UInt8
        let value: UInt16
    }

    struct vec3
    {
        let x, y, z: Float32
    }
    
    typealias Chars32 = (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                         CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                         CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                         CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar)

    typealias Chars64 = (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                         CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                         CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                         CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                         CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                         CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                         CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                         CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar)

    func charsToString(_ chars: Chars64) -> String
    {
        var bytes = chars
        
        return withUnsafePointer(to: &bytes) { ptr -> String in
           return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
        }
    }

    func charsToString(_ chars: (CChar, CChar, CChar, CChar)) -> String
    {
        var bytes = chars
        
        return withUnsafePointer(to: &bytes) { ptr -> String in
           return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
        }
    }
}
