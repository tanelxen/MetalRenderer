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
    
    // Read the map data from an NSData buffer containing the bsp file
    init(data: Data)
    {
        buffer = BinaryReader(data: data)
        
        readHeader()
    }
    
    private func readHeader()
    {
        print("============ READ MDL ============")
        
        let header: studiohdr_t = decode(data: (buffer.data as NSData))
        
        print(charsToString(header.magic))
        print(charsToString(header.name))
        
//        var nameBytes = header.name
//
//        let name: String = withUnsafePointer(to: &nameBytes) { ptr -> String in
//           return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
//        }
        
        var bodyparts: [mstudiobodyparts_t] = []
        
        for i in 0 ..< header.numbodyparts
        {
            let size = MemoryLayout<mstudiobodyparts_t>.size
            let start = Int(header.bodypartindex) + Int(i) * size
            
            let bodypartsRange = start ..< (start + size)
            
            let bodypartsData = buffer.data.subdata(in: bodypartsRange)
            
            let bodypart: mstudiobodyparts_t = decode(data: (bodypartsData as NSData))
            
            bodyparts.append(bodypart)
            
            print(charsToString(bodypart.name))
        }
        
        var models: [mstudiomodel_t] = []
        
        for bodypart in bodyparts
        {
            let index = Int(bodypart.modelindex)
            let size = MemoryLayout<mstudiomodel_t>.size
            
            for i in 0 ..< bodypart.nummodels
            {
                let start = index + Int(i) * size
                
                let range = start ..< (start + size)
                
                let data = buffer.data.subdata(in: range) as NSData
                
                let model: mstudiomodel_t = decode(data: data)
                
                models.append(model)
                
                print(charsToString(model.name))
            }
        }
        
        var meshes: [mstudiomesh_t] = []
        
        for model in models
        {
            let index = Int(model.meshindex)
            let size = MemoryLayout<mstudiomesh_t>.size
            
            for i in 0 ..< model.nummesh
            {
                let start = index + Int(i) * size
                
                let range = start ..< (start + size)
                
                let data = buffer.data.subdata(in: range) as NSData
                
                let mesh: mstudiomesh_t = decode(data: data)
                
                meshes.append(mesh)
            }
        }
    }
}

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

struct vec3
{
    let x, y, z: Float32
}

func decode<T>(data: NSData) -> T
{
    let pointer = UnsafeMutablePointer<T>.allocate(capacity: MemoryLayout.size(ofValue:T.self))
    data.getBytes(pointer, length: MemoryLayout<T>.size)
    
    return pointer.move()
}
