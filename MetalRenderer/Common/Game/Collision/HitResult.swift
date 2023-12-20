//
//  HitResult.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 21.12.2023.
//

import Foundation
import simd

struct HitResult
{
    var fraction: Float = 1
    var normal: float3?
    
    var endpos: float3 = .zero
    
    var startsolid = false
    var allsolid = false
}

struct TraceWork
{
    var start: float3 = .zero
    var end: float3 = .zero
    
    var mins: float3 = .zero
    var maxs: float3 = .zero
    
    // BoundingBox corners
    var offsets: [float3] = .init(repeating: .zero, count: 8)
    
    var sweepBox: BoundingBox!
    var checkedBrushIndeces: [Int] = []
    
    var fraction: Float = 1
    var startsolid = false
    var allsolid = false
    
    var plane: WorldCollisionAsset.Plane?
}
