//
//  Q3MapTrace.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 19.02.2022.
//

import Foundation
import simd

private struct trace_t
{
    var allsolid = false            // if true, plane is not valid
    var startsolid = false          // if true, the initial point was in a solid area
    var fraction: Float = 1.0       // time completed, 1.0 = didn't hit anything
    var endpos: float3 = .zero      // final position
}

private struct traceWork_t
{
    var start: float3 = .zero
    var end: float3 = .zero
    
    var mins: float3 = .zero
    var maxs: float3 = .zero
    var bounds: [float3] = [.zero, .zero]
    var isPoint: Bool = true
    var trace: trace_t = trace_t()
}

private let SURFACE_CLIP_EPSILON: Float = 0.125

class Q3MapTrace
{
    private let q3map: Q3Map
    
    init(q3map: Q3Map)
    {
        self.q3map = q3map
    }
    
    func trace(start: float3, end: float3)
    {
        var tw: traceWork_t = traceWork_t()
        
        tw.start = start
        tw.end = end
        tw.mins = .zero
        tw.maxs = .zero
        
        for i in 0 ..< 3
        {
            if tw.start[i] < tw.end[i]
            {
                tw.bounds[0][i] = tw.start[i] // + tw.size[0][i]
                tw.bounds[1][i] = tw.end[i] // + tw.size[1][i]
            }
            else
            {
                tw.bounds[0][i] = tw.end[i] // + tw.size[0][i]
                tw.bounds[1][i] = tw.start[i] // + tw.size[1][i]
            }
        }
        
        CheckNode(tw: &tw, num: 0, p1f: 0, p2f: 1, p1: start, p2: end)
    }
    
    private func CheckNode(tw: inout traceWork_t, num: Int, p1f: Float, p2f: Float, p1: float3, p2: float3)
    {
        var t1: Float = 0
        var t2: Float = 0
        var offset: Float = 0
        
        var frac: Float = 0
        var frac2: Float = 0
        var idist: Float = 0
        
        var mid: float3 = .zero
        var side: Int = 0
        var midf: Float = 0
        
        if tw.trace.fraction <= p1f {
            return     // already hit something nearer
        }

        // if < 0, we are in a leaf node
        if num < 0 {
            CheckLeaf(tw: &tw, index: -(num + 1))
            return
        }
        
        //
        // find the point distances to the separating plane
        // and the offset for the size of the box
        //
        let node = q3map.nodes[num]
        let plane = q3map.planes[node.plane]
        
        // adjust the plane distance apropriately for mins/maxs
        if plane.type == .PLANE_NON_AXIAL
        {
            t1 = dot(plane.normal, p1) - plane.distance
            t2 = dot(plane.normal, p2) - plane.distance
            
            offset = tw.isPoint ? 0 : 2048
        }
        else
        {
            t1 = p1[plane.type.rawValue] - plane.distance
            t2 = p2[plane.type.rawValue] - plane.distance
            offset = 0 // tw.extents[plane.type.rawValue]
        }
        
        // see which sides we need to consider
        if t1 >= offset + 1 && t2 >= offset + 1
        {
            CheckNode(tw: &tw, num: node.front, p1f: p1f, p2f: p2f, p1: p1, p2: p2)
            return
        }
        
        if ( t1 < -offset - 1 && t2 < -offset - 1 )
        {
            CheckNode(tw: &tw, num: node.back, p1f: p1f, p2f: p2f, p1: p1, p2: p2)
            return
        }
        
        // put the crosspoint SURFACE_CLIP_EPSILON pixels on the near side
        if t1 < t2
        {
            idist = 1.0 / (t1 - t2)
            side = 1
            frac2 = ( t1 + offset + SURFACE_CLIP_EPSILON ) * idist
            frac = ( t1 - offset + SURFACE_CLIP_EPSILON ) * idist
        }
        else if t1 > t2
        {
            idist = 1.0 / (t1 - t2)
            side = 0
            frac2 = ( t1 - offset - SURFACE_CLIP_EPSILON ) * idist
            frac = ( t1 + offset + SURFACE_CLIP_EPSILON ) * idist
        }
        else
        {
            side = 0
            frac = 1
            frac2 = 0
        }
        
        // move up to the node
        frac = max(0, min(1, frac))

        midf = p1f + (p2f - p1f) * frac
        mid = p1 + frac * (p2 - p1)
        
        CheckNode(tw: &tw, num: side == 0 ? node.front : node.back, p1f: p1f, p2f: midf, p1: p1, p2: mid)
        
        // go past the node
        frac2 = max(0, min(1, frac2))

        midf = p1f + (p2f - p1f) * frac2
        mid = p1 + frac2 * (p2 - p1)
        
        CheckNode(tw: &tw, num: side == 0 ? node.back : node.front, p1f: midf, p2f: p2f, p1: mid, p2: p2)
    }
    
    private func CheckLeaf(tw: inout traceWork_t, index: Int)
    {
        let leaf = q3map.leafs[index]
        
        for i in 0 ..< leaf.n_leafbrushes
        {
            let leafbrush = Int(q3map.leafbrushes[leaf.leafbrush + i])
            var brush = q3map.brushes[leafbrush]
            
//            if !(b->contents & tw->contents) { continue }
//            if !BoundsIntersect(tw->bounds[0], tw->bounds[1], b->bounds[0], b->bounds[1]) { continue }
            
            CheckBrush(tw: &tw, brush: &brush)
            
            if tw.trace.fraction != 0 { return }
        }
    }
    
    private func CheckBrush(tw: inout traceWork_t, brush: inout Q3Brush)
    {
    }
    
    private func BoundsIntersect(mins: float3, maxs: float3, mins2: float3, maxs2: float3) -> Bool
    {
        if (maxs[0] < mins2[0] - SURFACE_CLIP_EPSILON ||
            maxs[1] < mins2[1] - SURFACE_CLIP_EPSILON ||
            maxs[2] < mins2[2] - SURFACE_CLIP_EPSILON ||
            mins[0] > maxs2[0] + SURFACE_CLIP_EPSILON ||
            mins[1] > maxs2[1] + SURFACE_CLIP_EPSILON ||
            mins[2] > maxs2[2] + SURFACE_CLIP_EPSILON)
        {
            return false
        }

        return true
    }
}
