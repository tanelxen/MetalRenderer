//
//  WorldCollisionAsset+Q3BSP.swift
//  Sandbox
//
//  Created by Fedor Artemenkov on 05.10.2023.
//

import Foundation
import Quake3BSP
import simd

extension WorldCollisionAsset
{
    static func make(from bsp: Q3Map, folder: URL) -> WorldCollisionAsset
    {
        var asset = WorldCollisionAsset()
        
        asset.planes = bsp.planes.map { Plane(normal: $0.normal, distance: $0.distance) }
        asset.nodes = bsp.nodes.map { Node(plane: $0.plane, child: $0.child) }
        
        asset.leafs = bsp.leafs.map {
            let range = $0.leafbrush ..< $0.leafbrush + $0.n_leafbrushes
            let indices = bsp.leafbrushes[range].map { Int($0) }
            
            return Leaf(brushes: indices)
        }
        
        asset.brushes = bsp.brushes.map {
            Brush(
                name: nil,
                brushside: $0.brushside,
                numBrushsides: $0.numBrushsides,
                contentFlags: Int(bsp.textures[$0.texture].contentFlags)
            )
        }
        
        asset.brushSides = bsp.brushSides.map { BrushSide(plane: $0.plane) }
        
        asset.dirURL = folder
        
        let encoder = JSONEncoder()
        
        if let entitiesData = try? encoder.encode(asset)
        {
            let entitiesURL = folder.appendingPathComponent("collision.json")
            try? entitiesData.write(to: entitiesURL)
        }
        
        return asset
    }
    
    static func make(from bsp: Q3Map) -> WorldCollisionAsset
    {
        var asset = WorldCollisionAsset()
        
        asset.planes = bsp.planes.map { Plane(normal: $0.normal, distance: $0.distance) }
        asset.nodes = bsp.nodes.map { Node(plane: $0.plane, child: $0.child) }
        
        asset.leafs = bsp.leafs.map {
            let range = $0.leafbrush ..< $0.leafbrush + $0.n_leafbrushes
            let indices = bsp.leafbrushes[range].map { Int($0) }
            
            return Leaf(brushes: indices)
        }
        
        asset.brushes = bsp.brushes.map {
            Brush(
                name: nil,
                brushside: $0.brushside,
                numBrushsides: $0.numBrushsides,
                contentFlags: Int(bsp.textures[$0.texture].contentFlags)
            )
        }
        
        asset.brushSides = bsp.brushSides.map { BrushSide(plane: $0.plane) }
        
        return asset
    }
}
