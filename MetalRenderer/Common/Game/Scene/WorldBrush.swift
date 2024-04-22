//
//  WorldBrush.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 20.04.2024.
//

import Metal
import simd

final class WorldBrush
{
    var transform = Transform()
    private var corners: [float3] = .init(repeating: .zero, count: 8)
    private let faces: [Face]
    
    private var selectedFaceIndex: Int?
    
    var selectedFaceTransform: Transform? {
        
        get {
            guard let index = selectedFaceIndex else { return nil }
            
            let face = faces[index]
            let vertices = face.indices.map{ corners[$0] }
            
            let center = vertices.reduce(.zero, +) / 6 + transform.position
            
            let transform = Transform()
            transform.position = center
            
            return transform
        }
        
        set {
            guard let trans = newValue else { return }
            guard let index = selectedFaceIndex else { return }
            
            let face = faces[index]
            let pos = trans.position - transform.position
            
            for i in face.indices
            {
                if face.axis.x != 0
                {
                    corners[i].x = pos.x
                }
                
                if face.axis.y != 0
                {
                    corners[i].y = pos.y
                }
                
                if face.axis.z != 0
                {
                    corners[i].z = pos.z
                }
            }
        }
    }
    
    var selectedFaceNormal: float3? {
        guard let index = selectedFaceIndex else { return nil }
        return faces[index].axis
    }
    
    init()
    {
        let minBounds = float3(0, 0, 0)
        let maxBounds = float3(64, 64, 64)
        
        corners[0] = float3(minBounds.x, minBounds.y, minBounds.z)  // Back     Right   Bottom      0
        corners[1] = float3(maxBounds.x, minBounds.y, minBounds.z)  // Front    Right   Bottom      1
        corners[2] = float3(minBounds.x, maxBounds.y, minBounds.z)  // Back     Left    Bottom      2
        corners[3] = float3(maxBounds.x, maxBounds.y, minBounds.z)  // Front    Left    Bottom      3

        corners[4] = float3(minBounds.x, minBounds.y, maxBounds.z)  // Back     Right   Top         4
        corners[5] = float3(maxBounds.x, minBounds.y, maxBounds.z)  // Front    Right   Top         5
        corners[6] = float3(minBounds.x, maxBounds.y, maxBounds.z)  // Back     Left    Top         6
        corners[7] = float3(maxBounds.x, maxBounds.y, maxBounds.z)  // Front    Left    Top         7
        
        faces = [
            Face(indices: [4, 6, 5, 5, 6, 7], axis: float3(0, 0, 1)),   // Top
            Face(indices: [2, 0, 3, 3, 0, 1], axis: float3(0, 0, -1)),  // Bottom
            Face(indices: [0, 2, 4, 4, 2, 6], axis: float3(-1, 0, 0)),  // Back
            Face(indices: [3, 1, 7, 7, 1, 5], axis: float3(1, 0, 0)),   // Front
            Face(indices: [1, 0, 5, 5, 0, 4], axis: float3(0, -1, 0)),   // Right
            Face(indices: [2, 3, 6, 6, 3, 7], axis: float3(0, 1, 0)),  // Left
        ]
    }
    
    func selectFace(by ray: Ray)
    {
        selectedFaceIndex = nil
        
        for (index, face) in faces.enumerated()
        {
            guard dot(face.axis, ray.direction) < 0 else {
                continue
            }
            
            let point1 = lineIntersectTriangle(
                v0: corners[face.indices[0]] + transform.position,
                v1: corners[face.indices[1]] + transform.position,
                v2: corners[face.indices[2]] + transform.position,
                start: ray.origin,
                end: ray.origin + ray.direction * 1024
            )
            
            let point2 = lineIntersectTriangle(
                v0: corners[face.indices[3]] + transform.position,
                v1: corners[face.indices[4]] + transform.position,
                v2: corners[face.indices[5]] + transform.position,
                start: ray.origin,
                end: ray.origin + ray.direction * 1024
            )
            
            if point1 != nil || point2 != nil
            {
                selectedFaceIndex = index
                break
            }
        }
    }
    
    func render(with encoder: MTLRenderCommandEncoder?)
    {
        transform.updateModelMatrix()
        
        if let index = selectedFaceIndex, faces.indices.contains(index)
        {
            let selected = faces[index]
            drawFaces([selected], color: float4(1, 0, 0, 1), edges: false, with: encoder)
            
            var unselected = faces
            unselected.remove(at: index)
            drawFaces(unselected, color: float4(1, 1, 0, 1), edges: true, with: encoder)
        }
        else
        {
            drawFaces(self.faces, color: float4(1, 1, 0, 1), edges: true, with: encoder)
        }
    }
    
    private func drawFaces(_ faces: [Face], color: float4, edges: Bool, with encoder: MTLRenderCommandEncoder?)
    {
        var vertices = faces.flatMap({ $0.indices }).map({ BasicVertex(corners[$0]) })

        encoder?.setVertexBytes(&vertices, length: MemoryLayout<BasicVertex>.stride * vertices.count, index: 0)
        
        var modelConstants = ModelConstants()
        modelConstants.color = color
        modelConstants.modelMatrix = transform.matrix
        
        encoder?.setTriangleFillMode(.fill)
        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        encoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        
        if edges
        {
            var modelConstants2 = ModelConstants()
            modelConstants2.color = float4(0, 0, 0, 1)
            modelConstants2.modelMatrix = transform.matrix
            modelConstants2.modelMatrix.scale(axis: float3(repeating: 1.001))
            
            encoder?.setTriangleFillMode(.lines)
            encoder?.setVertexBytes(&modelConstants2, length: ModelConstants.stride, index: 2)
            encoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
            encoder?.setTriangleFillMode(.fill)
        }
    }
    
    struct Face
    {
        let indices: [Int]
        let axis: float3
    }
}

private struct BasicVertex
{
    let pos: float3
    let uv: float2
    
    init(_ x: Float, _ y: Float, _ z: Float, _ u: Float, _ v: Float)
    {
        self.pos = float3(x, y, z)
        self.uv = float2(u, v)
    }
    
    init(_ pos: float3)
    {
        self.pos = pos
        self.uv = .zero
    }
}