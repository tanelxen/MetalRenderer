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
    var uv: float2 = .zero
    var edge: HalfEdge!
    
    init(_ pos: float3)
    {
        position = pos
    }
    
    func isClose(to other: Vert) -> Bool
    {
        return length(position - other.position) < 0.1
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
    
    var isHighlighted = false
    
    init(_ name: String = "")
    {
        self.name = name
    }
    
    var fromTo: (Vert, Vert) {
        (pair!.vert, vert)
    }
}

class Face
{
    var name: String
    
    var edges: [HalfEdge] = []
    var verts: [Vert] = []
    var plane: Plane!
    
    var center: float3 {
        let points = verts.map { $0.position }
        return points.reduce(.zero, +) / Float(points.count)
    }
    
    var isHighlighted = false
    
    init(_ name: String = "")
    {
        self.name = name
    }
}

extension Vert: Hashable
{
    static func == (lhs: Vert, rhs: Vert) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

extension HalfEdge: Hashable
{
    static func == (lhs: HalfEdge, rhs: HalfEdge) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

// Iterates through half-edges around the given vertex.
// Got from https://github.com/gyk/TrivialSolutions
class VertexEdgeIterator: IteratorProtocol
{
    let centerVertex: Vert
    var currEdge: HalfEdge?

    init(_ centerVertex: Vert)
    {
        self.centerVertex = centerVertex
    }

    func next() -> HalfEdge?
    {
        if currEdge == nil
        {
            currEdge = self.centerVertex.edge
        }
        else if currEdge!.fromTo == self.centerVertex.edge!.fromTo
        {
            return nil
        }

        defer {
            currEdge = currEdge!.pair!.next
        }
        
        return currEdge
    }
}
