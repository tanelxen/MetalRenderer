//
//  BrushFace.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 11.05.2024.
//

import Foundation
import simd

private let BOGUS_RANGE: Float = 64 * 1024
private let ON_EPSILON: Float = 0.01
private let MAX_POINTS: Int = 64

private let SIDE_FRONT: Int = 0
private let SIDE_BACK: Int = 1
private let SIDE_ON: Int = 2
private let SIDE_CROSS: Int = -2

final class BrushFace
{
    let planeIndex: Int
    
    var points: [float3] = []
    var uvs: [float2] = []
    var numpoints = 0
    
//    var planePoints: [float3] = []
    
    var center: float3 {
        points.reduce(.zero, +) / Float(points.count)
    }
    
    init(planeIndex: Int)
    {
        self.planeIndex = planeIndex
    }
    
    func update(from planes: [Plane])
    {
        numpoints = 0
        
        let plane = planes[planeIndex]
        
        // get a poly that covers an effectively infinite area
        setupWindingBase(for: plane)
        
        // chop the poly by all of the other faces
        var past = false

        for i in planes.indices
        {
            if i == planeIndex {
                past = true
                continue
            }
            
            var clip = planes[i]
            
            // identical plane, use the later one
            if dot(plane.normal, clip.normal) > 0.999 && abs(plane.distance - clip.distance) < 0.01
            {
                // invalid face
                if past
                {
                    numpoints = 0
                    return
                }
                
                continue
            }

            // flip the plane, because we want to keep the back side
            clip.normal = -clip.normal
            clip.distance = -clip.distance
            
            windingClip(by: clip)
        }
        
        updateUVs(with: plane)
    }
    
    func clip(by planes: [Plane])
    {
        for clip in planes
        {
            windingClip(by: clip)
        }
    }
    
    /*
     Find large polygon
     */
    private func setupWindingBase(for plane: Plane)
    {
        var vup: float3 = .zero
        
        switch plane.mainAxis
        {
            case 0, 1:
                vup[2] = 1
                
            case 2:
                vup[0] = 1
                
            default:
                break
        }
        
        let v = dot(vup, plane.normal)
        vup = normalize(vup - plane.normal * v)
        
        let org = plane.normal * plane.distance
        
        var vright = cross(vup, plane.normal)
        
        vup = vup * BOGUS_RANGE
        vright = vright * BOGUS_RANGE

        // project a really big    axis aligned box onto the plane
        points = Array<float3>.init(repeating: .zero, count: 4)
        
        points[0] = org - vright + vup
        points[1] = org + vright + vup
        points[2] = org + vright - vup
        points[3] = org - vright - vup
        
        numpoints = 4
    }
    
    func windingClip(by split: Plane)
    {
        var sides = Array<Int>.init(repeating: 0, count: MAX_POINTS)
        var dists = Array<Float>.init(repeating: 0, count: MAX_POINTS)
        var counts: [Int] = [0, 0, 0]
        
        for i in points.indices
        {
            let dot = dot(points[i], split.normal) - split.distance
            
            dists[i] = dot
            
            if dot > ON_EPSILON {
                sides[i] = SIDE_FRONT
            }
            else if ( dot < -ON_EPSILON ) {
                sides[i] = SIDE_BACK
            }
            else {
                sides[i] = SIDE_ON
            }
            
            counts[sides[i]] += 1
        }
        
        sides[numpoints] = sides[0]
        dists[numpoints] = dists[0]
        
        var neww: [float3] = []
        
        for i in points.indices
        {
            let p1 = points[i]

            if sides[i] == SIDE_ON
            {
                neww.append(p1)
                continue
            }

            if sides[i] == SIDE_FRONT
            {
                neww.append(p1)
            }

            if sides[i + 1] == SIDE_ON || sides[i + 1] == sides[i]
            {
                continue
            }

            // generate a split point
            let p2 = points[(i + 1) % numpoints]

            let dot = dists[i] / ( dists[i] - dists[i + 1] )
            
            var mid: float3 = .zero
            
            for j in 0...2
            {
                if ( split.normal[j] == 1 ) {
                    mid[j] = split.distance
                }
                else if ( split.normal[j] == -1 ) {
                    mid[j] = -split.distance
                }
                else {
                    mid[j] = p1[j] + dot * ( p2[j] - p1[j] )
                }
            }
            
            neww.append(mid)
        }
        
        points = neww
        uvs = Array<float2>.init(repeating: .zero, count: points.count)
    }
    
    private func textureAxisFromPlane(normal: float3) -> (xv: float3, yv: float3)
    {
        var bestaxis: Int = 0
        var best: Float = 0

        for i in 0 ..< 6
        {
            let dot = dot(normal, baseaxis[i*3])
            
            if dot > best
            {
                best = dot
                bestaxis = i
            }
        }
        
        let xv = baseaxis[bestaxis*3+1]
        let yv = baseaxis[bestaxis*3+2]
        
        return (xv, yv)
    }
    
    func updateUVs(with plane: Plane)
    {
        let (xv, yv) = textureAxisFromPlane(normal: plane.normal)
        
        let matrix = float4x4(
            float4(xv.x, yv.x, plane.normal.x, 0),
            float4(xv.y, yv.y, plane.normal.y, 0),
            float4(xv.z, yv.z, plane.normal.z, 0),
            float4(0, 0, -plane.distance, 1)
        )
        
        for i in points.indices
        {
            var projected = matrix * float4(points[i], 1)
            projected = projected / projected.w
            projected = projected / 64
            
            uvs[i].x = projected.x
            uvs[i].y = projected.y
        }
    }
}

private extension Plane
{
    var mainAxis: Int {
        
        var axis: Int = -1
        var max: Float = -1
        
        for i in 0...2
        {
            let v = abs(normal[i])
            if v > max
            {
                axis = i
                max = v
            }
        }
        
        return axis
    }
}

private let baseaxis: [float3] = [
    [ 0,-1, 0], [-1, 0, 0], [0, 0,-1], // floor
    [ 0, 1, 0], [ 1, 0, 0], [0, 0,-1], // ceiling
    [-1, 0, 0], [ 0, 0,-1], [0,-1, 0], // west wall
    [ 1, 0, 0], [ 0, 0, 1], [0,-1, 0], // east wall
    [ 0, 0, 1], [-1, 0, 0], [0,-1, 0], // south wall
    [ 0, 0,-1], [ 1, 0, 0], [0,-1, 0]  // north wall
]
