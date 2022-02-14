//
//  Q3MapCollision.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 11.02.2022.
//

import Foundation
import simd

struct HitResult
{
    var start: float3 = .zero
    var end: float3 = .zero
    
    var point: float3 = .zero
    var normal: float3?
    
    var fraction: Float = 0.0
    var plane: Q3Plane?
}

class Q3MapCollision
{
//    private var outputFraction: Float = 0.0
//    private var outputEnd: float3 = .zero
    private var outputStartOut = false
    private var outputAllSolid = false
    
    private let EPSILON: Float = 0.125
    
    private enum TraceType
    {
        case TT_RAY
        case TT_SPHERE
        case TT_BOX
    }

    private var traceType: TraceType = .TT_RAY
    private var traceRadius: Float = 0.0
    private var traceMins: float3 = .zero
    private var traceMaxs: float3 = .zero
    private var traceExtents: float3 = .zero
    
    private let q3map: Q3Map
    
    init(q3map: Q3Map)
    {
        self.q3map = q3map
    }
    
    func traceRay(result: inout HitResult, start inputStart: float3, end inputEnd: float3)
    {
        traceType = .TT_RAY
        Trace(result: &result, start: inputStart, end: inputEnd)
    }

    func traceSphere(result: inout HitResult, start inputStart: float3, end inputEnd: float3, inputRadius: Float)
    {
        traceType = .TT_SPHERE
        traceRadius = inputRadius
        Trace(result: &result, start: inputStart, end: inputEnd)
    }
    
    func traceBox(result: inout HitResult, start inputStart: float3, end inputEnd: float3, mins inputMins: float3, maxs inputMaxs: float3)
    {
        if inputMins == .zero && inputMaxs == .zero
        {
            // the user TraceBox, but this is actually a ray
            return traceRay(result: &result, start: inputStart, end: inputEnd)
        }
        else
        {
            // setup for a box
            traceType = .TT_BOX
            traceMins = inputMins
            traceMaxs = inputMaxs
            
            traceExtents.x = -traceMins.x > traceMaxs.x ? -traceMins.x : traceMaxs.x
            traceExtents.y = -traceMins.y > traceMaxs.y ? -traceMins.y : traceMaxs.y
            traceExtents.z = -traceMins.z > traceMaxs.z ? -traceMins.z : traceMaxs.z
            
            Trace(result: &result, start: inputStart, end: inputEnd)
        }
    }
    
    private func Trace(result: inout HitResult, start inputStart: float3, end inputEnd: float3)
    {
        outputStartOut = true
        outputAllSolid = false
        
        result.start = inputStart
        result.end = inputEnd
        result.point = inputEnd
        
        result.fraction = 1.0
        result.normal = nil
        result.plane = nil

        // walk through the BSP tree
        CheckNode(result: &result, nodeIndex: 0, startFraction: 0.0, endFraction: 1.0, start: inputStart, end: inputEnd)

        if result.fraction == 1.0
        {
            // nothing blocked the trace
            result.point = inputEnd
        }
        else
        {
            // collided with something
            result.point = inputStart + result.fraction * (inputEnd - inputStart)
        }
    }
    
    private func CheckNode(result: inout HitResult, nodeIndex: Int, startFraction: Float, endFraction: Float, start: float3, end: float3)
    {
        // this is a leaf
        if nodeIndex < 0
        {
            CheckLeaf(result: &result, index: -(nodeIndex + 1))
            return
        }
        
        var offset: Float = 0.0
        
        let node = q3map.nodes[nodeIndex]
        let plane = q3map.planes[node.plane]
        
        // ======================================
        if traceType == .TT_RAY
        {
            offset = 0
        }
        else if traceType == .TT_SPHERE
        {
            offset = traceRadius
        }
        else if traceType == .TT_BOX
        {
            // this is just a dot product, but we want the absolute values
            offset = abs(traceExtents[0] * plane.normal[0]) + abs(traceExtents[1] * plane.normal[1]) + abs(traceExtents[2] * plane.normal[2])
        }
        // ======================================
        
        let startDistance = dot(start, plane.normal) - plane.distance
        let endDistance = dot(end, plane.normal) - plane.distance
        
        if startDistance >= offset && endDistance >= offset // both points are in front of the plane
        {
            // so check the front child
            CheckNode(result: &result, nodeIndex: node.front, startFraction: startFraction, endFraction: endFraction, start: start, end: end)
            return
        }
        
        if startDistance < -offset && endDistance < -offset // both points are behind the plane
        {
            // so check the back child
            CheckNode(result: &result, nodeIndex: node.back, startFraction: startFraction, endFraction: endFraction, start: start, end: end)
            return
        }
        
        // the line spans the splitting plane
        
        var side: Int
        var fraction1, fraction2, middleFraction: Float
        var middle: float3
        
        let inverseDistance: Float = 1.0 / (startDistance - endDistance)

        // STEP 1: split the segment into two
        if startDistance < endDistance
        {
            side = 1; // back
            fraction1 = (startDistance - offset + EPSILON) * inverseDistance
            fraction2 = (startDistance + offset + EPSILON) * inverseDistance
        }
        else if (endDistance < startDistance)
        {
            side = 0; // front
            fraction1 = (startDistance + offset + EPSILON) * inverseDistance
            fraction2 = (startDistance - offset - EPSILON) * inverseDistance
        }
        else
        {
            side = 0; // front
            fraction1 = 1.0
            fraction2 = 0.0
        }

        fraction1 = max(0, min(1, fraction1))
        fraction2 = max(0, min(1, fraction2))

        // STEP 3: calculate the middle point for the first side
        middleFraction = startFraction + (endFraction - startFraction) * fraction1
        middle = start + fraction1 * (end - start)
        

        // STEP 4: check the first side
        if side == 0
        {
            CheckNode(result: &result, nodeIndex: node.front, startFraction: startFraction, endFraction: middleFraction, start: start, end: middle)
        }
        else
        {
            CheckNode(result: &result, nodeIndex: node.back, startFraction: startFraction, endFraction: middleFraction, start: start, end: middle)
        }

        // STEP 5: calculate the middle point for the second side
        middleFraction = startFraction + (endFraction - startFraction) * fraction2
        middle = start + fraction2 * (end - start)

        // STEP 6: check the second side
        if side == 0
        {
            CheckNode(result: &result, nodeIndex: node.back, startFraction: startFraction, endFraction: middleFraction, start: start, end: middle)
        }
        else
        {
            CheckNode(result: &result, nodeIndex: node.front, startFraction: startFraction, endFraction: middleFraction, start: start, end: middle)
        }
    }
    
    private func CheckLeaf(result: inout HitResult, index: Int)
    {
        let leaf = q3map.leafs[index]
        
        for i in 0 ..< leaf.n_leafbrushes
        {
            let leafbrush = Int(q3map.leafbrushes[leaf.leafbrush + i])
            var brush = q3map.brushes[leafbrush]
            
//                let texture = q3map.textures[brush.texture]
//                let isSolid = (texture.contentFlags & 1) == 1
            
            if brush.brushside > 0// && isSolid
            {
                CheckBrush(result: &result, brush: &brush)
            }
        }
    }
    
    private func CheckBrush(result: inout HitResult, brush: inout Q3Brush)
    {
        var startFraction: Float = -1.0
        var endFraction: Float = 1.0
        var startsOut = false
        var endsOut = false
        
        var closestPlaneIndex: Int = -1
        
        for i in 0 ..< brush.numBrushsides
        {
            let brushSide = q3map.brushSides[brush.brushside + i]
            let plane = q3map.planes[brushSide.plane]
            
            var startDistance: Float = 0
            var endDistance: Float = 0
            
            if traceType == .TT_RAY
            {
                startDistance = dot(result.start, plane.normal) - plane.distance
                endDistance = dot(result.end, plane.normal) - plane.distance
            }
            else if traceType == .TT_SPHERE
            {
                startDistance = dot(result.start, plane.normal) - (plane.distance + traceRadius)
                endDistance = dot(result.end, plane.normal) - (plane.distance + traceRadius)
            }
            else if traceType == .TT_BOX
            {
                var offset: float3 = .zero
                
                offset.x = plane.normal.x < 0 ? traceMaxs.x : traceMins.x
                offset.y = plane.normal.y < 0 ? traceMaxs.y : traceMins.y
                offset.z = plane.normal.z < 0 ? traceMaxs.z : traceMins.z

                startDistance =
                    (result.start[0] + offset[0]) * plane.normal[0] +
                    (result.start[1] + offset[1]) * plane.normal[1] +
                    (result.start[2] + offset[2]) * plane.normal[2] - plane.distance
                
                endDistance =
                    (result.end[0] + offset[0]) * plane.normal[0] +
                    (result.end[1] + offset[1]) * plane.normal[1] +
                    (result.end[2] + offset[2]) * plane.normal[2] - plane.distance
            }

            if startDistance > 0
            {
                startsOut = true
            }
            
            if endDistance > 0
            {
                endsOut = true
            }

            // make sure the trace isn't completely on one side of the brush
            // both are in front of the plane, its outside of this brush
            if (startDistance > 0 && (endDistance >= EPSILON || endDistance >= startDistance)) { return }
            
            // both are behind this plane, it will get clipped by another one
            if (startDistance <= 0 && endDistance <= 0) { continue }
            

            // MMM... BEEFY
            // line is entering into the brush
            if startDistance > endDistance
            {
                let fraction = (startDistance - EPSILON) / (startDistance - endDistance)
                
                if fraction > startFraction
                {
                    startFraction = fraction
                    closestPlaneIndex = brushSide.plane
                }
            }
            else // line is leaving the brush
            {
                let fraction = (startDistance + EPSILON) / (startDistance - endDistance)
                
                endFraction = min(endFraction, fraction)
            }
        }
        
        if startFraction < endFraction && startFraction > -1 && startFraction < result.fraction
        {
            result.fraction = max(startFraction, 0)
            
            if closestPlaneIndex != -1
            {
                result.plane = q3map.planes[closestPlaneIndex]
                result.normal = q3map.planes[closestPlaneIndex].normal
            }
        }
        
        if !startsOut || !endsOut
        {
            result.fraction = 0
        }
    }
}

fileprivate func clamp<T>(_ value: T, minValue: T, maxValue: T) -> T where T : Comparable
{
    return min(max(value, minValue), maxValue)
}
