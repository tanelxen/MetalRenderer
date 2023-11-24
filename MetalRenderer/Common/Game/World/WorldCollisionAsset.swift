//
//  WorldCollisionAsset.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 06.10.2023.
//

import Foundation
import simd

struct WorldCollisionAsset: Codable
{
    var planes: [Plane] = []
    var nodes: [Node] = []
    var leafs: [Leaf] = []
    
    var brushes: [Brush] = []
    var brushSides: [BrushSide] = []
    
    var dirURL: URL!
    
    struct Plane: Codable
    {
        let normal: SIMD3<Float>
        let distance: Float
    }
    
    struct Brush: Codable
    {
        let brushside: Int
        let numBrushsides: Int
        let contentFlags: Int
    }
    
    struct BrushSide: Codable
    {
        let plane: Int
    }
    
    struct Node: Codable
    {
        let plane: Int
        let child: [Int]
    }
    
    struct Leaf: Codable
    {
        let brushes: [Int]
    }
}

extension WorldCollisionAsset
{
    static func load(with packageURL: URL) -> WorldCollisionAsset?
    {
        let dataFileURL = packageURL.appendingPathComponent("collision.json")
        
        do
        {
            let data = try Data(contentsOf: dataFileURL)
            
            let decoder = JSONDecoder()
            return try decoder.decode(WorldCollisionAsset.self, from: data)
        }
        catch
        {
            return nil
        }
    }
}
