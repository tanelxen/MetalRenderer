//
//  SkeletalMeshAsset.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 10.09.2023.
//

import Foundation
import GoldSrcMDL

struct SkeletalMeshAsset: Codable
{
    let name: String
    let surfaces: [Surface]
    let textures: [String]
    
    init(valveModel: ValveModel)
    {
        name = valveModel.modelName
        
        surfaces = valveModel.meshes.map {
            let verticies = $0.vertexBuffer.map {
                Vertex(position: $0.position, texCoord: $0.texCoord, boneIndex: $0.boneIndex)
            }
            
            return Surface(vertices: verticies, triangles: $0.indexBuffer, textureIndex: $0.textureIndex)
        }
        
        textures = valveModel.textures.map {
            $0.name
        }
    }

    struct Surface: Codable
    {
        let vertices: [Vertex]
        let triangles: [Int]
        let textureIndex: Int
    }
    
    struct Vertex: Codable
    {
        let position: SIMD3<Float>
        let texCoord: SIMD2<Float>
        let boneIndex: Int
    }
}

extension SkeletalMeshAsset
{
    func save()
    {
        do
        {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(self)
            
            let url = ResourceManager.URLInDocuments(for: "\(name).json")
            try jsonData.write(to: url)
        }
        catch
        {
            print(error.localizedDescription)
        }
    }
}
