//
//  Intersection.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 18.09.2023.
//

import Foundation
import simd

func intersection(ray: Ray, plane: Plane) -> float3?
{
    let dotProduct = dot(ray.direction, plane.normal)
    
    if abs(dotProduct) < 0.000001 { return nil }
    
    let t = (plane.distance - dot(ray.origin, plane.normal)) / dotProduct
    
    if t < 0 { return nil }
    
    return (ray.origin + ray.direction * t)
    
//        return round(result * 1000) / 1000
}

func lineIntersectTriangle(v0: float3, v1: float3, v2: float3, start: float3, end: float3) -> float3?
{
    let n = normalize(cross(v1 - v0, v2 - v1))

    let d1 = dot(start - v0, n)
    let d2 = dot(end - v0, n)

    // Проверка на пересечение плоскости треугольника
    guard (d1 < 0 && d2 > 0) || (d1 > 0 && d2 < 0) else {
        return nil
    }

    let p = start + (end - start) * (-d1 / (d2 - d1))

    // Проверка, лежит ли точка p внутри треугольника
    let e1 = cross(v1 - v0, p - v0)
    let e2 = cross(v2 - v1, p - v1)
    let e3 = cross(v0 - v2, p - v2)

    guard dot(e1, n) >= 0, dot(e2, n) >= 0, dot(e3, n) >= 0 else {
        return nil
    }

    return p
}

func lineIntersectionAABB(start: float3, end: float3, mins: float3, maxs: float3) -> Bool
{
    var dirfrac = float3()
    
    let line = end - start
    let dir = normalize(line)
    let dist = length(line)

    dirfrac.x = 1.0 / dir.x
    dirfrac.y = 1.0 / dir.y
    dirfrac.z = 1.0 / dir.z

    let tx1 = (mins.x - start.x) * dirfrac.x
    let tx2 = (maxs.x - start.x) * dirfrac.x

    var tmin = min(tx1, tx2)
    var tmax = max(tx1, tx2)

    let ty1 = (mins.y - start.y) * dirfrac.y
    let ty2 = (maxs.y - start.y) * dirfrac.y

    tmin = max(tmin, min(ty1, ty2))
    tmax = min(tmax, max(ty1, ty2))

    let tz1 = (mins.z - start.z) * dirfrac.z
    let tz2 = (maxs.z - start.z) * dirfrac.z

    tmin = max(tmin, min(tz1, tz2))
    tmax = min(tmax, max(tz1, tz2))

    return tmax >= max(0, tmin) && tmin < dist
}

func findIntersection(start: float3, end: float3, mins: float3, maxs: float3) -> float3?
{
    var tmin = (mins - start) / (end - start)
    var tmax = (maxs - start) / (end - start)

    // Ensure tmin and tmax are sorted
    if tmin.x > tmax.x { swap(&tmin.x, &tmax.x) }
    if tmin.y > tmax.y { swap(&tmin.y, &tmax.y) }
    if tmin.z > tmax.z { swap(&tmin.z, &tmax.z) }

    let tminMax = max(max(tmin.x, tmin.y), tmin.z)
    let tmaxMin = min(min(tmax.x, tmax.y), tmax.z)

    // Check for intersection
    if tminMax > tmaxMin {
        // No intersection
        return nil
    }

    // Intersection point
    let intersectionPoint = start + (end - start) * tminMax
    return intersectionPoint
}

enum Intersection
{
    struct Line
    {
        let start: float3
        let end: float3
    }
    
    struct AABB
    {
        let mins: float3
        let maxs: float3
    }
    
    struct Result
    {
        let point: float3
        let normal: float3
        let index: Int
    }
    
    static func findIntersection(line: Line, aabbs: [AABB]) -> Result?
    {
        var closestIntersection: Result?
        var closestT: Float = .greatestFiniteMagnitude
        
        let dir = line.end - line.start
        
        for (index, aabb) in aabbs.enumerated()
        {
            let t1 = (aabb.mins - line.start) / dir
            let t2 = (aabb.maxs - line.start) / dir
            
            let tmin = max(max(min(t1.x, t2.x), min(t1.y, t2.y)), min(t1.z, t2.z))
            let tmax = min(min(max(t1.x, t2.x), max(t1.y, t2.y)), max(t1.z, t2.z))
            
            if tmin <= tmax && tmin < closestT
            {
                // Intersection found
                let point = line.start + dir * tmin
                
                // Determine the normal based on which face of the AABB was hit
                var normal = float3(0, 0, 0)
                
                for i in 0...2
                {
                    if tmin == t1[i] {
                        normal[i] = -1.0
                        break
                    }
                    
                    if tmin == t2[i] {
                        normal[i] = 1.0
                        break
                    }
                }
                
                // Adjust the normal to reflect the correct axis of intersection
                if normal.x != 0 {
                    normal.y = 0
                    normal.z = 0
                } else if normal.y != 0 {
                    normal.x = 0
                    normal.z = 0
                } else {
                    normal.x = 0
                    normal.y = 0
                }
                
                closestT = tmin
                closestIntersection = Result(point: point, normal: normal, index: index)
            }
        }
        
        return closestIntersection
    }
}
