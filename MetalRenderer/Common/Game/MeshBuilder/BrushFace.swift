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

final class BrushPoly
{
    weak var face: BrushFace!
    
    var points: [float3] = []
    var uvs: [float2] = []
//    var normal: float3 = .zero
    
    init(points: [float3])
    {
        self.points = points
        self.uvs = Array<float2>.init(repeating: .zero, count: points.count)
        
//        if points.count > 2
//        {
//            let v1 = points[1] - points[0]
//            let v2 = points[2] - points[0]
//            self.normal = normalize(cross(v2, v1))
//        }
    }
    
    func check(against plane: Plane) -> Category
    {
        var iFront: Int = 0
        var iBack: Int = 0
        var iOnPlane: Int = 0
        
        for point in points
        {
            let result = dot(plane.normal, point) - plane.distance
            
            if result > 0
            {
                iFront += 1
            }
            else if result < 0
            {
                iBack += 1
            }
            else
            {
                iOnPlane += 1
            }
        }
        
        if iFront == points.count
        {
            return .front
        }
        if iBack == points.count
        {
            return .back
        }
        if iOnPlane == points.count
        {
            return .aligned
        }
        
        return .split
    }
    
    enum Category
    {
        case aligned
        case front
        case back
        case split
    }
}

// Recursive pushing poly down bsp-tree (list of planes)
private func carve(poly: BrushPoly, planes: [Plane], index: Int) -> [BrushPoly]
{
    guard index < planes.count
    else {
        return []
    }
    
    let plane = planes[index]
    
    switch poly.check(against: plane)
    {
        case .front:
            // early out - poly is outside the brush
            return [poly]
            
        case .aligned:
            return carve(poly: poly, planes: planes, index: index + 1)
            
        case .back:
            return carve(poly: poly, planes: planes, index: index + 1)
            
        case .split:
            let frontPoints = split(points: poly.points, plane: plane)
            let frontPoly = BrushPoly(points: frontPoints)
            frontPoly.face = poly.face
            
            let inverted = Plane(normal: -plane.normal, distance: -plane.distance)
            let backPoints = split(points: poly.points, plane: inverted)
            let backPoly = BrushPoly(points: backPoints)
            backPoly.face = poly.face
            
            let back2 = carve(poly: backPoly, planes: planes, index: index + 1)
            
            var result = [frontPoly]
            result.append(contentsOf: back2)
            return result
    }
}

private enum PointClassify
{
    case front, back, align
}

private func split(points: [float3], plane: Plane) -> [float3]
{
    var relations: [PointClassify] = []
    var dists: [Float] = []
    
    for point in points
    {
        let dist = dot(plane.normal, point) - plane.distance
        
        dists.append(dist)
        
        if dist < -ON_EPSILON {
            relations.append(.back)
        } else if dist > ON_EPSILON {
            relations.append(.front)
        } else {
            relations.append(.align)
        }
    }
    
    var front: [float3] = []
    
    for i in points.indices
    {
        let curr = i
        let next = (i + 1) % points.count
        
        let p1 = points[curr]
        let p2 = points[next]
        
        let r1 = relations[curr]
        let r2 = relations[next]
        
        if r1 == .align
        {
            front.append(p1)
            continue
        }
        
        if r1 == .front
        {
            front.append(p1)
        }
        
        if r2 == .align || r2 == r1
        {
            continue
        }
        
        let t = dists[curr] / (dists[curr] - dists[next])
        
        let mid = p1 + (p2 - p1) * t
        
        front.append(mid)
    }
    
    return front
}

final class BrushFace
{
    let planeIndex: Int
    
    var points: [float3] = []
    var numpoints = 0
    
    var polys: [BrushPoly] = []
    
//    var planePoints: [float3] = []
    
    private (set) var plane: Plane!
    
    var center: float3 {
        points.reduce(.zero, +) / Float(points.count)
    }
    
    var isHighlighted = false
    
    init(planeIndex: Int)
    {
        self.planeIndex = planeIndex
    }
    
    func update(from planes: [Plane])
    {
        numpoints = 0
        
        plane = planes[planeIndex]
        
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
    
    func clip(with other: PlainBrush)
    {
        var result: [BrushPoly] = []
        
        for poly in polys
        {
            let fragments = carve(poly: poly, planes: other.planes, index: 0)
            result.append(contentsOf: fragments)
        }
        
        self.polys = result
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
        
        let poly = BrushPoly(points: points)
        poly.face = self
        polys = [poly]
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
        
        for i in polys.indices
        {
            for j in polys[i].points.indices
            {
                var projected = matrix * float4(polys[i].points[j], 1)
                projected = projected / projected.w
                projected = projected / 64
                
                polys[i].uvs[j].x = projected.x
                polys[i].uvs[j].y = projected.y
            }
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
