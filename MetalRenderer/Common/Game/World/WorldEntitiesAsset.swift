//
//  WorldEntitiesAsset.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 06.10.2023.
//

import Foundation
import simd

struct WorldEntitiesAsset: Codable
{
    var entities: [Entity] = []
    var dirURL: URL!
    
    struct Entity: Codable
    {
        let classname: String

        let position: SIMD3<Float>
        let rotation: SIMD3<Float>
        
        let properties: [String: String]
    }
}

extension WorldEntitiesAsset
{
    static func load(with packageURL: URL) -> WorldEntitiesAsset?
    {
        let dataFileURL = packageURL.appendingPathComponent("entities.json")
        
        do
        {
            let data = try Data(contentsOf: dataFileURL)
            
            let decoder = JSONDecoder()
            return try decoder.decode(WorldEntitiesAsset.self, from: data)
        }
        catch
        {
            return nil
        }
    }
}
