//
//  SkeletalMeshAsset.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 10.09.2023.
//

import Foundation
import simd

struct SkeletalMeshAsset
{
    var name: String = ""
    var textures: [String] = []
    var surfaces: [Surface] = []
    var sequences: [Sequence] = []
    var vertices: [Vertex] = []
    var indices: [UInt32] = []
    var bones: [Int32] = []

    struct Surface
    {
        let firstIndex: Int
        let indexCount: Int
        let textureIndex: Int
    }
    
    struct Vertex
    {
        let position: SIMD3<Float>
        let texCoord: SIMD2<Float>
        let boneIndex: Int
    }
    
    struct Sequence
    {
        let name: String
        let frames: [Frame]
        let fps: Float
        let groundSpeed: Float
    }
    
    struct Frame
    {
        let rotationPerBone: [SIMD3<Float>]
        let positionPerBone: [SIMD3<Float>]
    }
}
