//
//  Types.swift
//  
//
//  Created by Fedor Artemenkov on 25.09.2023.
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
    public let rotationPerBone: [SIMD3<Float>]
    public let positionPerBone: [SIMD3<Float>]
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
    public var bones: [Int] = []
}
