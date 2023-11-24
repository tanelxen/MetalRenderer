//
//  WorldStaticMeshAsset.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 06.10.2023.
//

import Foundation
import simd

struct WorldStaticMeshAsset
{
    var surfaces: [Surface] = []
    var vertices: [Vertex] = []
    var indices: [UInt32] = []
    
    var textures: [String] = []
    
    var dirURL: URL!

    struct Surface
    {
        let firstIndex: Int
        let indexCount: Int
        let textureIndex: Int
        let isLightmapped: Bool
    }
    
    struct Vertex
    {
        let position: SIMD3<Float>
        let texCoord0: SIMD2<Float>
        let texCoord1: SIMD2<Float>
        let color: SIMD3<Float>
    }
}
