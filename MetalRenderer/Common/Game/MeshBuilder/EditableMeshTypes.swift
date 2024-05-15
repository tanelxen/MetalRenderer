//
//  EditableMeshTypes.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 15.05.2024.
//

import Metal
import simd

class Vert
{
    var position: float3
    var edge: HalfEdge!
    
    init(_ pos: float3)
    {
        position = pos
    }
}

class HalfEdge
{
    var name: String
    
    var vert: Vert!
    var face: Face!
    
    var pair: HalfEdge!
    var next: HalfEdge!
    var prev: HalfEdge!
    
    var center: float3 {
        (vert.position + next.vert.position) * 0.5
    }
    
    init(_ name: String = "")
    {
        self.name = name
    }
}

class Face
{
    var name: String
    
    var edges: [HalfEdge] = []
    var verts: [Vert] = []
    
    var normal: float3 = .zero
    var plane: Plane!
    
    var center: float3 {
        let points = verts.map { $0.position }
        return points.reduce(.zero, +) / Float(points.count)
    }
    
    init(_ name: String = "")
    {
        self.name = name
    }
}
