//
//  BrushRenderer.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 06.10.2023.
//

import Foundation
import Metal
import simd

final class BrushRenderer
{
    private struct BrushSet
    {
        var color: float3 = .one
        var verticesCount = 0
        var vertexBuffer: MTLBuffer?
        var vertices: [BasicVertex] = []
    }
    
    private var brushes: [BrushSet] = []
    private var texture: MTLTexture!
    
    func loadFromAsset(_ asset: WorldCollisionAsset)
    {
        var map: [Int: BrushSet] = [:]
        
        for brush in asset.brushes
        {
            if map[brush.contentFlags] == nil {
                map[brush.contentFlags] = BrushSet()
            }
            
            let sides = asset.brushSides[brush.brushside ..< brush.brushside + brush.numBrushsides]
            let planes = sides.map { asset.planes[$0.plane] }

            let brushVertices = createVertices(planes: planes)

            map[brush.contentFlags]?.vertices.append(contentsOf: brushVertices)
        }
        
        for key in map.keys
        {
            map[key]!.vertexBuffer = Engine.device.makeBuffer(
                bytes: map[key]!.vertices,
                length: MemoryLayout<BasicVertex>.stride * map[key]!.vertices.count,
                options: []
            )
            
            map[key]!.verticesCount = map[key]!.vertices.count
            map[key]!.vertices = []
            
            map[key]!.color = CONTENTS.allCases.first(where: { key.contains($0) })?.color ?? .zero
            
            brushes.append(map[key]!)
        }
        
        texture = TextureManager.shared.getTexture(for: "Assets/notex.png")
    }
    
    func render(with encoder: MTLRenderCommandEncoder)
    {
        encoder.setFragmentTexture(texture, index: 0)
        
        for brush in brushes
        {
            guard brush.vertexBuffer != nil else { continue }
            
            var modelConstants = ModelConstants()
            modelConstants.color = float4(.one, 0.5)
            encoder.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
            
            encoder.setVertexBuffer(brush.vertexBuffer, offset: 0, index: 0)
            
//            encoder.setCullMode(.none)
//            encoder.setTriangleFillMode(.lines)
            
            encoder.drawPrimitives(type: .triangle,
                                   vertexStart: 0,
                                   vertexCount: brush.verticesCount)
        }
    }
    
    private func createVertices(planes: [Plane]) -> [BasicVertex]
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

                    if isPointInsideVolume(vertex: vertex.pos, planes: planes)
                    {
                        faces[i].vertices.append(vertex)
                        faces[j].vertices.append(vertex)
                        faces[k].vertices.append(vertex)
                    }
                }
            }
        }
        
        var result: [BasicVertex] = []
        
        for var face in faces
        {
            guard face.vertices.count >= 3 else { continue }
            
            face.sortVertices()
            face.updateUVs()
            
            result.append(face.vertices[0])
            result.append(face.vertices[face.vertices.count - 1])
            result.append(face.vertices[1])
            
            for i in 1 ..< face.vertices.count/2
            {
                result.append(face.vertices[i])
                result.append(face.vertices[face.vertices.count - i])
                result.append(face.vertices[i + 1])
                
                result.append(face.vertices[face.vertices.count - i])
                result.append(face.vertices[face.vertices.count - i - 1])
                result.append(face.vertices[i + 1])
            }
        }
        
        return result
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
    
    private func intersection(_ p1: Plane, _ p2: Plane, _ p3: Plane) -> BasicVertex?
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
        
        return BasicVertex(p.x, p.y, p.z, 0, 0)
    }
}

private struct BasicVertex
{
    var pos: float3
    var uv: float2
    
    init(_ x: Float, _ y: Float, _ z: Float, _ u: Float, _ v: Float)
    {
        self.pos = float3(x, y, z)
        self.uv = float2(u, v)
    }
}

extension BrushRenderer
{
    private typealias Plane = WorldCollisionAsset.Plane
//    private typealias Vertex = SIMD3<Float>
    
    private struct Face
    {
        let plane: Plane
        var vertices: [BasicVertex] = []
        
        var center: float3 {
            return vertices.reduce(.zero, { $0 + $1.pos }) / Float(vertices.count)
        }
        
        mutating func sortVertices()
        {
            let c = center + 1e-5
            let n = plane.normal
            
            vertices = vertices.sorted(by: {
                
                let ca = c - $0.pos
                let cb = c - $1.pos
                let caXcb = normalize(cross(ca, cb))
                
                return dot(n, caXcb) >= 0
            })
        }
        
        mutating func updateUVs()
        {
            let (xv, yv) = textureAxisFromPlane(normal: plane.normal)
            
            let matrix = float4x4(
                float4(xv.x, yv.x, plane.normal.x, 0),
                float4(xv.y, yv.y, plane.normal.y, 0),
                float4(xv.z, yv.z, plane.normal.z, 0),
                float4(0, 0, -plane.distance, 1)
            )
            
            for i in 0 ..< vertices.count
            {
                var projected = matrix * float4(vertices[i].pos, 1)
                projected = projected / projected.w
                projected = projected / 64
                
                vertices[i].uv.x = projected.x
                vertices[i].uv.y = projected.y
            }
        }
        
        private let baseaxis: [float3] = [
            float3(0,0,1), float3(1,0,0), float3(0,-1,0),            // floor
            float3(0,0,-1), float3(1,0,0), float3(0,-1,0),        // ceiling
            float3(1,0,0), float3(0,1,0), float3(0,0,-1),            // west wall
            float3(-1,0,0), float3(0,1,0), float3(0,0,-1),        // east wall
            float3(0,1,0), float3(1,0,0), float3(0,0,-1),            // south wall
            float3(0,-1,0), float3(1,0,0), float3(0,0,-1)            // north wall
        ]
        
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
    }
}
