//
//  WorldEntitiesAsset+Q3BSP.swift
//  Sandbox
//
//  Created by Fedor Artemenkov on 05.10.2023.
//

import Foundation
import Quake3BSP
import simd

extension WorldEntitiesAsset
{
    static func make(from bsp: Q3Map, folder: URL) -> WorldEntitiesAsset
    {
        var asset = WorldEntitiesAsset()
        asset.dirURL = folder
        
        for info in bsp.entities
        {
            guard let classname = info["classname"]
            else {
                continue
            }
            
            guard let origin = info["origin"]?.split(separator: " ").compactMap({ Float($0) }),
                  origin.count == 3
            else {
                continue
            }
            
            let position = float3(origin[0], origin[1], origin[2])
            var rotation = float3(0, 0, 0)
            
            if let angle = info["angle"], let yaw = Float(angle)
            {
                rotation.z = yaw
            }
            
            var properties = info
            properties["classname"] = nil
            properties["origin"] = nil
            properties["angle"] = nil
            
            let entity = WorldEntitiesAsset.Entity(
                classname: classname,
                position: position,
                rotation: rotation,
                properties: properties
            )
            
            asset.entities.append(entity)
        }
        
        let encoder = JSONEncoder()
        
        if let entitiesData = try? encoder.encode(asset)
        {
            let entitiesURL = folder.appendingPathComponent("entities.json")
            try? entitiesData.write(to: entitiesURL)
        }
        
        return asset
    }
    
    static func make(from bsp: Q3Map) -> WorldEntitiesAsset
    {
        var asset = WorldEntitiesAsset()
        
        for info in bsp.entities
        {
            guard let classname = info["classname"]
            else {
                continue
            }
            
            guard let origin = info["origin"]?.split(separator: " ").compactMap({ Float($0) }),
                  origin.count == 3
            else {
                continue
            }
            
            let position = float3(origin[0], origin[1], origin[2])
            var rotation = float3(0, 0, 0)
            
            if let angle = info["angle"], let yaw = Float(angle)
            {
                rotation.z = yaw
            }
            
            var properties = info
            properties["classname"] = nil
            properties["origin"] = nil
            properties["angle"] = nil
            
            let entity = WorldEntitiesAsset.Entity(
                classname: classname,
                position: position,
                rotation: rotation,
                properties: properties
            )
            
            asset.entities.append(entity)
        }
        
        return asset
    }
}
