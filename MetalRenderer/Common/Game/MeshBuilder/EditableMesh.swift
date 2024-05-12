//
//  BrushTypes.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.05.2024.
//

import Foundation

class Vert
{
    var position: float3 = .zero
    var edge: HalfEdge!
}

class HalfEdge
{
    var vert: Vert!
    var face: Face!
    
    var pair: HalfEdge!
    var next: HalfEdge!
}

class Face
{
    var edges: [HalfEdge] = []
    var verts: [Vert] = []
}
