//
//  BrushCollision.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 24.11.2023.
//

import Foundation
import simd

final class BrushCollision
{
    struct BrushSet
    {
        var vertices: [float3] = []
    }
    
    private (set) var brushes: [BrushSet] = []
    
    func loadFromAsset(_ asset: WorldCollisionAsset)
    {
        for brush in asset.brushes
        {
            if !(brush.contentFlags.contains(.SOLID) || brush.contentFlags.contains(.PLAYERCLIP)) {
                continue
            }
            
            let sides = asset.brushSides[brush.brushside ..< brush.brushside + brush.numBrushsides]
            let planes = sides.map { asset.planes[$0.plane] }

            let brushVertices = createVertices(planes: planes)
            
            if brushVertices.isEmpty
            {
                print("brush.numBrushsides", brush.numBrushsides)
                continue
            }
            
            let set = BrushSet(vertices: brushVertices)
            brushes.append(set)
        }
    }
    
    private func createVertices(planes: [Plane]) -> [float3]
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
        
//        var set: Set<float3> = []
//
//        for face in faces
//        {
//            guard face.vertices.count >= 3 else { continue }
//
//            for vertex in face.vertices
//            {
//                set.insert(vertex)
//            }
//        }
        
        return faces.flatMap { $0.vertices }
    }
    
    private func isPointInsideVolume(vertex: SIMD3<Float>, planes: [Plane]) -> Bool
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
    
    private func intersection(_ p1: Plane, _ p2: Plane, _ p3: Plane) -> float3?
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

private extension BrushCollision
{
    private typealias Plane = WorldCollisionAsset.Plane
//    private typealias Vertex = SIMD3<Float>
    
    private struct Face
    {
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
                
                let ca = c - $0
                let cb = c - $1
                let caXcb = normalize(cross(ca, cb))
                
                return dot(n, caXcb) >= 0
            })
        }
    }
}

private enum CONTENTS: Int, CaseIterable
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

private extension Int
{
    func contains(_ value: CONTENTS) -> Bool
    {
        self & value.rawValue != 0
    }
}

