//
//  HashGrid.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 20.12.2023.
//

import Foundation
import simd

final class HashGrid
{
    private var grid: [GridKey: [Brush]] = [:]
    private let cellSize: Float = 64
    
    private var brushes: [Brush] = []
    private var bounds = BoundingBox(min: .zero, max: .zero)
    
    func loadFromAsset(_ asset: WorldCollisionAsset)
    {
        for (index, brush) in asset.brushes.enumerated()
        {
            if !(brush.contentFlags.contains(.SOLID) || brush.contentFlags.contains(.PLAYERCLIP)) {
                continue
            }
            
            let name = brush.name ?? "brush_\(index)"
            
            let sides = asset.brushSides[brush.brushside ..< brush.brushside + brush.numBrushsides]
            let planes = sides.map { asset.planes[$0.plane] }
            
            let brush = Brush(planes: planes)
            brush.name = name
            brush.id = index
            
            brushes.append(brush)
        }
        
        for brush in brushes
        {
            insert(brush)
        }
    }
    
    private func cellForPoint(_ point: float3) -> (Int, Int, Int)
    {
        let x = floor(point.x / cellSize)
        let y = floor(point.y / cellSize)
        let z = floor(point.z / cellSize)
        
        return (Int(x), Int(y), Int(z))
    }
    
    private func insert(_ brush: Brush)
    {
        let (minX, minY, minZ) = cellForPoint(brush.bounds.min)
        let (maxX, maxY, maxZ) = cellForPoint(brush.bounds.max)
        
        for x in minX...maxX
        {
            for y in minY...maxY
            {
                for z in minZ...maxZ
                {
                    let hash = GridKey(x, y, z)
                    
                    if grid[hash] == nil
                    {
                        grid[hash] = [brush]
                    }
                    else
                    {
                        grid[hash]?.append(brush)
                    }
                }
            }
        }
    }
    
    private func queryBrushes(in region: BoundingBox) -> [Brush]
    {
        var result: [Brush] = []
        
        let (minX, minY, minZ) = cellForPoint(region.min)
        let (maxX, maxY, maxZ) = cellForPoint(region.max)
        
        for x in minX...maxX
        {
            for y in minY...maxY
            {
                for z in minZ...maxZ
                {
                    let hash = GridKey(x, y, z)
                    
                    if let objects = grid[hash]
                    {
                        result.append(contentsOf: objects)
                    }
                }
            }
        }
        
        return result
    }
    
    private func isIntersect(_ first: BoundingBox, _ second: BoundingBox) -> Bool
    {
        return (first.min.x <= second.max.x && first.max.x >= second.min.x &&
                first.min.y <= second.max.y && first.max.y >= second.min.y &&
                first.min.z <= second.max.z && first.max.z >= second.min.z)
    }
    
    private func overallBoundingBox(for objects: [Brush]) -> BoundingBox
    {
        var minValues = SIMD3<Float>(repeating: Float.greatestFiniteMagnitude)
        var maxValues = SIMD3<Float>(repeating: -Float.greatestFiniteMagnitude)
        
        for object in objects
        {
            minValues.x = min(minValues.x, object.minBounds.x)
            minValues.y = min(minValues.y, object.minBounds.y)
            minValues.z = min(minValues.z, object.minBounds.z)
            
            maxValues.x = max(maxValues.x, object.maxBounds.x)
            maxValues.y = max(maxValues.y, object.maxBounds.y)
            maxValues.z = max(maxValues.z, object.maxBounds.z)
        }
        
        return BoundingBox(min: minValues, max: maxValues)
    }
    
    private func overallBoundingBox(for boxes: [BoundingBox]) -> BoundingBox
    {
        var minValues = SIMD3<Float>(repeating: Float.greatestFiniteMagnitude)
        var maxValues = SIMD3<Float>(repeating: -Float.greatestFiniteMagnitude)
        
        for box in boxes
        {
            minValues.x = min(minValues.x, box.min.x)
            minValues.y = min(minValues.y, box.min.y)
            minValues.z = min(minValues.z, box.min.z)
            
            maxValues.x = max(maxValues.x, box.max.x)
            maxValues.y = max(maxValues.y, box.max.y)
            maxValues.z = max(maxValues.z, box.max.z)
        }
        
        return BoundingBox(min: minValues, max: maxValues)
    }
}

extension HashGrid
{
    func traceBox(result: inout HitResult, start: float3, end: float3, mins: float3, maxs: float3)
    {
        var work = TraceWork()
        
        // Make symmetrical
        for i in 0...2
        {
            let offset = (mins[i] + maxs[i]) * 0.5
            
            work.mins[i] = mins[i] - offset
            work.maxs[i] = maxs[i] - offset
            work.start[i] = start[i] + offset
            work.end[i] = end[i] + offset
        }
        
        work.offsets[0][0] = work.mins[0]
        work.offsets[0][1] = work.mins[1]
        work.offsets[0][2] = work.mins[2]
        
        work.offsets[1][0] = work.maxs[0]
        work.offsets[1][1] = work.mins[1]
        work.offsets[1][2] = work.mins[2]
        
        work.offsets[2][0] = work.mins[0]
        work.offsets[2][1] = work.maxs[1]
        work.offsets[2][2] = work.mins[2]
        
        work.offsets[3][0] = work.maxs[0]
        work.offsets[3][1] = work.maxs[1]
        work.offsets[3][2] = work.mins[2]
        
        work.offsets[4][0] = work.mins[0]
        work.offsets[4][1] = work.mins[1]
        work.offsets[4][2] = work.maxs[2]
        
        work.offsets[5][0] = work.maxs[0]
        work.offsets[5][1] = work.mins[1]
        work.offsets[5][2] = work.maxs[2]
        
        work.offsets[6][0] = work.mins[0]
        work.offsets[6][1] = work.maxs[1]
        work.offsets[6][2] = work.maxs[2]
        
        work.offsets[7][0] = work.maxs[0]
        work.offsets[7][1] = work.maxs[1]
        work.offsets[7][2] = work.maxs[2]
        
        let eps = float3(SURF_CLIP_EPSILON, SURF_CLIP_EPSILON, SURF_CLIP_EPSILON)
        
        work.sweepBox = overallBoundingBox(for: [
            BoundingBox(min: start + mins - eps, max: start + maxs + eps),
            BoundingBox(min: end + mins - eps, max: end + maxs + eps)
        ])
        
        let overlapped = queryBrushes(in: work.sweepBox)
        
        for item in overlapped
        {
            if work.checkedBrushIndeces.contains(item.id) {
                continue
            }
            
            work.checkedBrushIndeces.append(item.id)
            
            trace_brush(item, work: &work)
            
            if work.allsolid {
                break
            }
        }
        
        result.fraction = work.fraction
        result.normal = work.plane?.normal
        
        result.startsolid = work.startsolid
        result.allsolid = work.allsolid
        
        result.endpos = start + work.fraction * (end - start)
    }
    
    private func trace_brush(_ brush: Brush, work: inout TraceWork)
    {
        guard isIntersect(work.sweepBox, brush.bounds) else { return }
        
        var start_frac: Float = -1.0
        var end_frac: Float = 1.0
        var closest_plane: WorldCollisionAsset.Plane?
        
        var getout = false
        var startout = false
        
        for plane in brush.planes
        {
            let signbits = plane.signbits
            let dist = plane.distance - dot(work.offsets[signbits], plane.normal)

            let start_distance = dot(work.start, plane.normal) - dist
            let end_distance = dot(work.end, plane.normal) - dist

            if start_distance > 0
            {
                startout = true
            }
            
            if end_distance > 0
            {
                getout = true // endpoint is not in solid
            }

            // make sure the trace isn't completely on one side of the brush
            // both are in front of the plane, its outside of this brush
            if (start_distance > 0 && (end_distance >= SURF_CLIP_EPSILON || end_distance >= start_distance)) { return }
            
            // both are behind this plane, it will get clipped by another one
            if (start_distance <= 0 && end_distance <= 0) { continue }
            

            if start_distance > end_distance
            {
                let frac = (start_distance - SURF_CLIP_EPSILON) / (start_distance - end_distance)
                
                if frac > start_frac
                {
                    start_frac = frac
                    closest_plane = plane
                }
            }
            else // line is leaving the brush
            {
                let frac = (start_distance + SURF_CLIP_EPSILON) / (start_distance - end_distance)
                
                end_frac = min(end_frac, frac)
            }
        }
        
        if !startout
        {
            // original point was inside brush
            work.startsolid = true
            
            if !getout
            {
                work.allsolid = true
                work.fraction = 0
            }
            
            return
        }
        
        if start_frac < end_frac && start_frac > -1 && start_frac < work.fraction
        {
            work.fraction = max(start_frac, 0)
            work.plane = closest_plane
        }
    }
}

fileprivate let SURF_CLIP_EPSILON: Float = 0.125

private extension WorldCollisionAsset.Plane
{
    var signbits: Int {
        var bits = 0
        
        for i in 0...2
        {
            if normal[i] < 0 {
                bits |= 1 << i
            }
        }
        
        return bits
    }
}

struct GridKey: Hashable
{
    let x: Int
    let y: Int
    let z: Int
    
    init(_ x: Int, _ y: Int, _ z: Int)
    {
        self.x = x
        self.y = y
        self.z = z
    }
}
