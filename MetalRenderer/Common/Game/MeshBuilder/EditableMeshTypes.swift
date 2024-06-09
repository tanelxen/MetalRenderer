//
//  EditableMeshTypes.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 15.05.2024.
//

import Metal
import simd

final class Vert
{
    var position: float3
    var uv: float2 = .zero
    var edge: HalfEdge!
    
    var neighbours: Set<Vert> = []
    
    init(_ pos: float3)
    {
        position = pos
    }
    
    func isClose(to other: Vert) -> Bool
    {
        return length(position - other.position) < 0.1
    }
}

final class HalfEdge
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
    
    var fromTo: (Vert, Vert?) {
        (vert, pair?.vert)
    }
}

final class Face
{
    var name: String
    
    var edges: [HalfEdge] = []
    var verts: [Vert] = []
    var plane: Plane!
    
    var center: float3 {
        let points = verts.map { $0.position }
        return points.reduce(.zero, +) / Float(points.count)
    }
    
    var texSize: float2 = [64, 64]
    var uvOffset: float2 = .zero
    var uvScale: float2 = .one
    
    var isHighlighted = false
    var isGhost = false
    
    var triangles: [Vert] = []
    
    func triangulate()
    {
        triangles.removeAll(keepingCapacity: true)
        
        guard verts.count > 3 else {
            
            if verts.count == 3 {
                triangles = verts
            }
            
            return
        }
        
        var vertices = verts // Копируем вершины в локальный массив для модификаций
        
        while vertices.count > 3
        {
            let n = vertices.count
            var earFound = false
            
            for i in 0..<n {
                let prevIndex = (i + n - 1) % n
                let nextIndex = (i + 1) % n
                let prevVertex = vertices[prevIndex]
                let currentVertex = vertices[i]
                let nextVertex = vertices[nextIndex]
                
                let convex = isConvex(prevVertex.position, currentVertex.position, nextVertex.position)
                let inTriangle = isPointInTriangle(vertices: vertices, a: prevVertex.position, b: currentVertex.position, c: nextVertex.position)
                
                if convex && !inTriangle {
                    
                    // Ухо найдено, добавляем его в результат
                    triangles.append(prevVertex)
                    triangles.append(currentVertex)
                    triangles.append(nextVertex)
                    
                    // Удаляем текущую вершину
                    vertices.remove(at: i)
                    earFound = true
                    break
                }
            }
            
            // Если не найдено ухо, это может означать, что полигон не является простым или данные некорректны.
            if !earFound {
                print("Ошибка: не удалось найти ухо для триангуляции.")
                break
            }
        }
        
        // Добавляем оставшийся треугольник
        if vertices.count == 3 {
            triangles.append(contentsOf: vertices)
        }
    }
    
    init(_ name: String = "")
    {
        self.name = name
    }
    
    private func isConvex(_ prev: float3, _ curr: float3, _ next: float3) -> Bool
    {
        let a = next - curr
        let b = prev - curr
        
        let crossProduct = SIMD3<Float>(
            a.y * b.z - a.z * b.y,
            a.z * b.x - a.x * b.z,
            a.x * b.y - a.y * b.x
        )
        
        return dot(crossProduct, curr - prev) >= 0
    }
    
    private func isPointInTriangle(vertices: [Vert], a: float3, b: float3, c: float3) -> Bool {
        for vertex in vertices {
            let p = vertex.position
            if p != a && p != b && p != c && isPointInTriangle(p, a, b, c) {
                return true
            }
        }
        return false
    }
    
    private func isPointInTriangle(_ p: float3, _ a: float3, _ b: float3, _ c: float3) -> Bool {
        let v0 = c - a
        let v1 = b - a
        let v2 = p - a
        
        let dot00 = dot(v0, v0)
        let dot01 = dot(v0, v1)
        let dot02 = dot(v0, v2)
        let dot11 = dot(v1, v1)
        let dot12 = dot(v1, v2)
        
        let invDenom = 1 / (dot00 * dot11 - dot01 * dot01)
        let u = (dot11 * dot02 - dot01 * dot12) * invDenom
        let v = (dot00 * dot12 - dot01 * dot02) * invDenom
        
        return (u >= 0) && (v >= 0) && (u + v < 1)
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

extension Face: Hashable
{
    static func == (lhs: Face, rhs: Face) -> Bool {
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
    var started: Bool

    init(_ centerVertex: Vert)
    {
        self.centerVertex = centerVertex
        self.started = false
        
    }

    func next() -> HalfEdge?
    {
        // If it's the first call to next()
        if !started
        {
            currEdge = self.centerVertex.edge
            started = true
            return currEdge
        }

        // Check if we've completed a full loop
        if currEdge?.pair?.next == self.centerVertex.edge
        {
            return nil
        }

        // Move to the next edge, handling the case where the pair may be nil
        if let pair = currEdge?.pair
        {
            currEdge = pair.next
        }
        else
        {
            // If there is no pair, stop iteration
            currEdge = nil
            return nil
        }

        return currEdge
    }
}
