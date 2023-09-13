//
//  Q3MapCollision.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 11.02.2022.
//

import simd
import Quake3BSP

struct HitResult
{
    var start: float3 = .zero
    var end: float3 = .zero
    
    var mins: float3 = .zero
    var maxs: float3 = .zero
    
    var offsets: [float3] = .init(repeating: .zero, count: 8)
    
    var endpos: float3 = .zero
    
    var fraction: Float = 0.0
    
    var plane: Q3Plane?
    
    var startsolid = false
    var allsolid = false
}

fileprivate let CONTENTS_SOLID: Int32 = 1

fileprivate struct PlaneInfo
{
    let type: PlaneType
    let signbits: Int
    
    init(normal: float3)
    {
        type = PlaneType(normal: normal)
        
        var bits = 0
        
        for i in 0...2
        {
            if normal[i] < 0 {
                bits |= 1 << i
            }
        }
        
        signbits = bits
    }
}

fileprivate let SURF_CLIP_EPSILON: Float = 0.125

class Q3MapCollision
{
    private let q3map: Q3Map
    private var planesInfo: [PlaneInfo] = []
    
    init(q3map: Q3Map)
    {
        self.q3map = q3map
        
        initPlanesInfo()
    }
    
    private func initPlanesInfo()
    {
        planesInfo = q3map.planes.map { PlaneInfo(normal: $0.normal) }
    }
    
    func traceRay(result: inout HitResult, start inputStart: float3, end inputEnd: float3)
    {
        traceBox(result: &result, start: inputStart, end: inputEnd, mins: .zero, maxs: .zero)
    }
    
    func traceBox(result work: inout HitResult, start: float3, end: float3, mins: float3, maxs: float3)
    {
        work.fraction = 1
        
        // Делаем симетричный AABB для упрощения проверок
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

        // walk through the BSP tree
        trace_node(work: &work, index: 0, start_frac: 0, end_frac: 1, start: work.start, end: work.end)

        if work.fraction == 1.0
        {
            // nothing blocked the trace
            work.endpos = end
        }
        else
        {
            // collided with something
            work.endpos = start + work.fraction * (end - start)
        }
    }
    
    private func trace_node(work: inout HitResult, index: Int, start_frac: Float, end_frac: Float, start: float3, end: float3)
    {
        // this is a leaf
        if index < 0
        {
            trace_leaf(at: -(index + 1), with: &work)
            return
        }
        
        let node = q3map.nodes[index]
        let plane = q3map.planes[node.plane]
        let plane_type = planesInfo[node.plane].type
        
        let offset: Float
        let start_distance: Float
        let end_distance: Float
        
        if plane_type.rawValue < 3
        {
            start_distance = start[plane_type.rawValue] - plane.distance
            end_distance = end[plane_type.rawValue] - plane.distance
            offset = work.maxs[plane_type.rawValue]
        }
        else
        {
            start_distance = dot(start, plane.normal) - plane.distance
            end_distance = dot(end, plane.normal) - plane.distance

            if work.maxs == work.mins {
                offset = 0
            } else {
                /* "this is silly" - id Software */
                offset = 2048
            }
        }
        
        if start_distance >= offset + 1 && end_distance >= offset + 1
        {
            trace_node(work: &work, index: node.child[0], start_frac: start_frac, end_frac: end_frac, start: start, end: end)
            return
        }
        
        if start_distance < -offset - 1 && end_distance < -offset - 1
        {
            trace_node(work: &work, index: node.child[1], start_frac: start_frac, end_frac: end_frac, start: start, end: end)
            return
        }
        
        // the line spans the splitting plane
        
        var side: Int
        var frac1, frac2, mid_frac: Float
        var mid: float3

        // split the segment into two
        if start_distance < end_distance
        {
            side = 1 // back
            let idistance = 1.0 / (start_distance - end_distance)
            frac1 = (start_distance - offset + SURF_CLIP_EPSILON) * idistance
            frac2 = (start_distance + offset + SURF_CLIP_EPSILON) * idistance
        }
        else if (end_distance < start_distance)
        {
            side = 0 // front
            let idistance = 1.0 / (start_distance - end_distance)
            frac1 = (start_distance + offset + SURF_CLIP_EPSILON) * idistance
            frac2 = (start_distance - offset - SURF_CLIP_EPSILON) * idistance
        }
        else
        {
            side = 0 // front
            frac1 = 1
            frac2 = 0
        }

        frac1 = max(0, min(1, frac1))
        frac2 = max(0, min(1, frac2))

        // calculate the middle point for the first side
        mid_frac = start_frac + (end_frac - start_frac) * frac1
        mid = start + (end - start) * frac1
        

        // check the first side
        trace_node(work: &work, index: node.child[side], start_frac: start_frac, end_frac: mid_frac, start: start, end: mid)

        // calculate the middle point for the second side
        mid_frac = start_frac + (end_frac - start_frac) * frac2
        mid = start + (end - start) * frac2

        // check the second side
        trace_node(work: &work, index: node.child[side^1], start_frac: mid_frac, end_frac: end_frac, start: mid, end: end)
    }
    
    private func trace_leaf(at index: Int, with work: inout HitResult)
    {
        let leaf = q3map.leafs[index]
        
        for i in 0 ..< leaf.n_leafbrushes
        {
            let brush_index = Int(q3map.leafbrushes[leaf.leafbrush + i])
            let brush = q3map.brushes[brush_index]
            
            let contentFlags = q3map.textures[brush.texture].contentFlags
            
            if brush.brushside > 0 && (contentFlags & CONTENTS_SOLID != 0)
            {
                trace_brush(brush, work: &work)
                
                if work.allsolid {
                    return
                }
            }
        }
    }
    
    private func trace_brush(_ brush: Q3Brush, work: inout HitResult)
    {
        var start_frac: Float = -1.0
        var end_frac: Float = 1.0
        var closest_plane: Q3Plane?
        
        var getout = false
        var startout = false
        
        for i in 0 ..< brush.numBrushsides
        {
            let side_index = brush.brushside + i
            let plane_index = q3map.brushSides[side_index].plane
            let plane = q3map.planes[plane_index]
            let signbits = planesInfo[plane_index].signbits
            
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

fileprivate func clamp<T>(_ value: T, minValue: T, maxValue: T) -> T where T : Comparable
{
    return min(max(value, minValue), maxValue)
}
