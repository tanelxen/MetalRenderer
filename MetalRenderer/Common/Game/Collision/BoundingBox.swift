//
//  BoundingBox.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 21.12.2023.
//

import Foundation

struct BoundingBox
{
    let min: float3
    let max: float3
    
    let center: float3
    let size: float3
    
    // Minkowski sum
    func minkowski(with other: BoundingBox) -> BoundingBox
    {
        return BoundingBox(
            min: min - other.size * 0.5,
            max: max + other.size * 0.5
        )
    }
    
    init(min: float3, max: float3)
    {
        self.min = min
        self.max = max
        
        self.center = (min + max) * 0.5
        self.size = max - min
    }
}
