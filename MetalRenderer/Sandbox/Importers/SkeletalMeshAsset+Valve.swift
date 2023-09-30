//
//  SkeletalMeshAsset+Valve.swift
//  Sandbox
//
//  Created by Fedor Artemenkov on 28.09.2023.
//

import Foundation
import GoldSrcMDL
import simd

extension SkeletalMeshAsset
{
    static func make(from model: ValveModel) -> SkeletalMeshAsset
    {
        var asset = SkeletalMeshAsset()
        
        asset.name = model.modelName
        
        var vertexOffset = 0
        var indexOffset = 0
        
        for i in 0 ..< model.meshes.count
        {
            let mesh = model.meshes[i]
            
            let indices = mesh.indexBuffer.map { UInt32($0 + vertexOffset) }
            asset.indices.append(contentsOf: indices)
            
            let surface = Surface(
                firstIndex: indexOffset,
                indexCount: indices.count,
                textureIndex: mesh.textureIndex
            )
            
            let vertices = mesh.vertexBuffer.map {
                Vertex(position: $0.position, texCoord: $0.texCoord, boneIndex: $0.boneIndex)
            }
            
            asset.surfaces.append(surface)
            asset.vertices.append(contentsOf: vertices)
            
            vertexOffset += mesh.vertexBuffer.count
            indexOffset += indices.count
        }
        
        asset.textures = model.textures.map { $0.name }
        
        for sequence in model.sequences
        {
            let frames = sequence.frames.map {
                Frame(rotationPerBone: $0.rotationPerBone, positionPerBone: $0.positionPerBone)
            }
            
            let seq = Sequence(
                name: sequence.name,
                frames: frames,
                fps: sequence.fps,
                groundSpeed: sequence.groundSpeed
            )
            
            asset.sequences.append(seq)
        }
        
        asset.bones = model.bones.map { Int32($0) }
        
        return asset
    }
}
