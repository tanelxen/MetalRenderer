//
//  NavigationMesh.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 18.09.2023.
//

import Foundation
import MetalKit
import DetourPathfinder

final class NavigationMesh
{
    private var vertexBuffer: MTLBuffer!
    
    private var unselectedIndexBuffer: MTLBuffer!
    private var unselectedIndicesCount: Int = 0
    
    private let pathfinder = DetourPathfinder()
    
    var isDebugDrawable = true
    
    init(detour data: Data)
    {
        pathfinder.load(from: data)
        setupRenderData()
    }
    
    func renderWithEncoder(_ encoder: MTLRenderCommandEncoder)
    {
        guard isDebugDrawable else { return }
        
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        var modelConstants = ModelConstants()
        
        modelConstants.color = float4(0, 1, 0, 0.6)
        encoder.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: unselectedIndicesCount,
                                      indexType: .uint16,
                                      indexBuffer: unselectedIndexBuffer,
                                      indexBufferOffset: 0)
    }
    
    private func setupRenderData()
    {
        let (verts, polys) = pathfinder.simpleMesh()
        
        let vertices = verts.map({ BasicVertex(pos: float3($0.x, -$0.z, $0.y)) })
        let indices = polys.map({ UInt16($0) })
        
        vertexBuffer = Engine.device.makeBuffer(bytes: vertices,
                                                length: vertices.count * MemoryLayout<BasicVertex>.stride,
                                                options: [])
        
        unselectedIndexBuffer = Engine.device.makeBuffer(bytes: indices,
                                                         length: indices.count * MemoryLayout<UInt16>.stride,
                                                         options: [])
        
        unselectedIndicesCount = indices.count
    }
}

extension NavigationMesh
{
    func makeRoute(from startPos: float3, to endPos: float3) -> [float3]
    {
        let spos = float3(startPos.x, startPos.z, -startPos.y)
        let epos = float3(endPos.x, endPos.z, -endPos.y)
        let ext = float3(0, 56, 0)
        
        let path = pathfinder.findPath(start: spos, end: epos, halfExtents: ext)
        
        return path.map { float3($0.x, -$0.z, $0.y) }
    }
    
    func makeRandomRoute(from startPos: float3) -> [float3]
    {
        let spos = float3(startPos.x, startPos.z, -startPos.y)
        let ext = float3(0, 56, 0)
        
        let path = pathfinder.randomPath(from: spos, halfExtents: ext)
        
        return path.map { float3($0.x, -$0.z, $0.y) }
    }
}

private struct BasicVertex
{
    let pos: float3
    let uv: float2 = .zero
}
