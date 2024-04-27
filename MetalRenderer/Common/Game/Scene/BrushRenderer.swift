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
        
        var texture: MTLTexture!
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
        
        print(map.keys)
        
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
            
            map[key]!.texture = CONTENTS.allCases.first(where: { key.contains($0) })?.texture
            
            brushes.append(map[key]!)
        }
        
        texture = TextureManager.shared.getTexture(for: "Assets/notex.png")
    }
    
    func render(with encoder: MTLRenderCommandEncoder)
    {
        for brush in brushes
        {
            guard brush.vertexBuffer != nil else { continue }
            
            var modelConstants = ModelConstants()
            modelConstants.color = float4(.one, 0.5)
            encoder.setVertexBytes(&modelConstants, length: MemoryLayout<ModelConstants>.size, index: 2)
            
            encoder.setVertexBuffer(brush.vertexBuffer, offset: 0, index: 0)
            
//            encoder.setCullMode(.none)
//            encoder.setTriangleFillMode(.lines)
            
            if let texture = brush.texture
            {
                encoder.setFragmentTexture(texture, index: 0)
            }
            else
            {
                encoder.setFragmentTexture(texture, index: 0)
            }
            
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
    
    var texture: MTLTexture? {
        
        switch self
        {
            case .AREAPORTAL: return TextureManager.shared.getTexture(for: "Assets/textures/common/areaportal.tga")
            case .CLUSTERPORTAL: return TextureManager.shared.getTexture(for: "Assets/textures/common/clusterportal.tga")
            case .FOG: return TextureManager.shared.getTexture(for: "Assets/textures/common/fog.tga")
            case .MONSTERCLIP: return TextureManager.shared.getTexture(for: "Assets/textures/common/clipmonster.tga")
            case .SOLID: return TextureManager.shared.getTexture(for: "Assets/textures/common/nodraw.tga")
            case .PLAYERCLIP: return TextureManager.shared.getTexture(for: "Assets/textures/common/clip.tga")
            case .TRIGGER: return TextureManager.shared.getTexture(for: "Assets/textures/common/trigger.tga")
                
            default: return nil
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
