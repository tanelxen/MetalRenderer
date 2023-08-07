//
//  Q3MapLightGrid.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.08.2023.
//

import simd
import Quake3BSP

final class Q3MapLightGrid
{
    private var maxs: float3 = .zero
    private var mins: float3 = .zero
    
    private var lightVolSizeX: Int = 0
    private var lightVolSizeY: Int = 0
    private var lightVolSizeZ: Int = 0
    
    private var ambients: [float3] = []
    private var positions: [float3] = []
    
    init(q3map: Q3Map)
    {
        maxs = q3map.models.first?.maxs ?? .zero
        mins = q3map.models.first?.mins ?? .zero
        
        lightVolSizeX = Int(floor(maxs.x / 64) - ceil(mins.x / 64) + 1)
        lightVolSizeY = Int(floor(maxs.y / 64) - ceil(mins.y / 64) + 1)
        lightVolSizeZ = Int(floor(maxs.z / 128) - ceil(mins.z / 128) + 1)
        
        ambients = q3map.lightgrid.map({ $0.ambient })
    }
    
    func ambient(at pos: float3) -> float3
    {
        guard ambients.count > 0 else { return .zero }
        
        let cellX = Int(floor(pos.x / 64) - ceil(mins.x / 64) + 1)
        let cellY = Int(floor(pos.y / 64) - ceil(mins.y / 64) + 1)
        let cellZ = Int(floor(pos.z / 128) - ceil(mins.z / 128) + 1)
        
        let index = indexForCell(x: cellX, y: cellY, z: cellZ)

        guard ambients.count > index else { return .zero }

        return ambients[index]
    }
    
    private func indexForCell(x: Int, y: Int, z: Int) -> Int
    {
        let cellX = min(max(x, 0), lightVolSizeX)
        let cellY = min(max(y, 0), lightVolSizeY)
        let cellZ = min(max(z, 0), lightVolSizeZ)
        
        return cellX + cellY * lightVolSizeX + cellZ * lightVolSizeX * lightVolSizeY
    }
}
