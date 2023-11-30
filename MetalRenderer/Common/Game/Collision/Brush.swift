//
//  Brush.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 30.11.2023.
//

import Foundation
import simd

class Brush
{
    typealias Plane = WorldCollisionAsset.Plane
    
    let planes: [Plane]
    let vertices: [float3]
    let triangles: [float3]
    
    let minBounds: float3
    let maxBounds: float3
    
    init(planes: [Plane])
    {
        self.planes = planes
        
        let faces = Self.createFaces(planes: planes)
        
        self.vertices = faces.flatMap { $0.vertices }
        
        var polys: [float3] = []
        
        for var face in faces
        {
            guard face.vertices.count >= 3 else { continue }
            
            face.sortVertices()
            
            polys.append(face.vertices[0])
            polys.append(face.vertices[face.vertices.count - 1])
            polys.append(face.vertices[1])
            
            for i in 1 ..< face.vertices.count/2
            {
                polys.append(face.vertices[i])
                polys.append(face.vertices[face.vertices.count - i])
                polys.append(face.vertices[i + 1])
                
                polys.append(face.vertices[face.vertices.count - i])
                polys.append(face.vertices[face.vertices.count - i - 1])
                polys.append(face.vertices[i + 1])
            }
        }
        
        self.triangles = polys
        
        var minValues = float3(repeating: Float.greatestFiniteMagnitude)
        var maxValues = float3(repeating: -Float.greatestFiniteMagnitude)
        
        for vertex in vertices
        {
            minValues.x = min(minValues.x, vertex.x)
            minValues.y = min(minValues.y, vertex.y)
            minValues.z = min(minValues.z, vertex.z)

            maxValues.x = max(maxValues.x, vertex.x)
            maxValues.y = max(maxValues.y, vertex.y)
            maxValues.z = max(maxValues.z, vertex.z)
        }
        
        self.minBounds = minValues
        self.maxBounds = maxValues
    }
}

extension Brush
{
    private static func createFaces(planes: [Plane]) -> [Face]
    {
        var faces = planes.map({ Face(plane: $0) })
        
        for i in 0 ..< planes.count - 2
        {
            for j in i ..< planes.count - 1
            {
                for k in j ..< planes.count
                {
                    guard i != j && i != k && j != k
                    else { continue }

                    guard let vertex = intersection(planes[i], planes[j], planes[k])
                    else { continue }

                    if isPointInsideVolume(vertex: vertex, planes: planes)
                    {
                        faces[i].vertices.append(vertex)
                        faces[j].vertices.append(vertex)
                        faces[k].vertices.append(vertex)
                    }
                }
            }
        }
        
        return faces
    }
    
    private static func isPointInsideVolume(vertex: SIMD3<Float>, planes: [Plane]) -> Bool
    {
        for plane in planes
        {
            let distanceToPlane = dot(plane.normal, vertex) - plane.distance
            
            if distanceToPlane > 1e-5
            {
                return false
            }
        }
        
        return true
    }
    
    private static func intersection(_ p1: Plane, _ p2: Plane, _ p3: Plane) -> float3?
    {
        let n1 = p1.normal
        let n2 = p2.normal
        let n3 = p3.normal
        
        let d1 = p1.distance
        let d2 = p2.distance
        let d3 = p3.distance
        
        let denom = dot(n1, cross(n2, n3))
        
        if (denom <= 1e-5 && denom >= -1e-5)  { return nil }
        
        var p = d1 * cross(n2, n3) + d2 * cross(n3, n1) + d3 * cross(n1, n2)
        p /= denom
        
        return p
    }
}

private struct Face
{
    typealias Plane = WorldCollisionAsset.Plane
    
    let plane: Plane
    var vertices: [float3] = []
    
    var center: float3 {
        return vertices.reduce(.zero, { $0 + $1 }) / Float(vertices.count)
    }
    
    mutating func sortVertices()
    {
        let c = center + 1e-5
        let n = plane.normal
        
        vertices = vertices.sorted(by: {
            
            let ca = c - $1
            let cb = c - $0
            let caXcb = normalize(cross(ca, cb))
            
            return dot(n, caXcb) >= 0
        })
    }
}

enum CONTENTS: Int, CaseIterable
{
    case AREAPORTAL = 0x8000
    case BODY = 0x2000000
    case CLUSTERPORTAL = 0x100000
    case CORPSE = 0x4000000
    case DETAIL = 0x8000000
    case DONOTENTER = 0x200000
    case FOG = 64
    case JUMPPAD = 0x80000
    case LAVA = 8
    case MONSTERCLIP = 0x20000
    case NODROP = 0x80000000
    case ORIGIN = 0x1000000
    case PLAYERCLIP = 0x10000
    case SLIME = 16
    case SOLID = 1
    case STRUCTURAL = 0x10000000
    case TELEPORTER = 0x40000
    case TRANSLUCENT = 0x20000000
    case TRIGGER = 0x40000000
    case WATER = 32
    
    var color: float3 {
        
        switch self
        {
            case .AREAPORTAL: return float3(0.1, 0.1, 1)
            case .CLUSTERPORTAL: return float3(1, 1, 0)
            case .FOG: return float3(0.5, 0.5, 0.5)
            case .MONSTERCLIP: return float3(0.9, 0.5, 0)
            case .PLAYERCLIP: return float3(1, 0.5, 0)
            case .SOLID: return float3(1, 0, 0)
            case .TRANSLUCENT: return float3(1, 1, 1)
            case .TRIGGER: return float3(1, 0, 1)
            case .WATER: return float3(0, 0, 1)
                
            default: return float3(0, 0.5, 0)
        }
    }
}

extension Int
{
    func contains(_ value: CONTENTS) -> Bool
    {
        self & value.rawValue != 0
    }
}

