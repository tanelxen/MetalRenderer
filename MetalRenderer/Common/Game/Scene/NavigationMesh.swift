//
//  NavigationMesh.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 18.09.2023.
//

import Foundation
import MetalKit

final class NavigationMesh
{
    private var vertexBuffer: MTLBuffer!
    private var indexBuffer: MTLBuffer!
    private var indexCount: Int = 0
    
    private var asset: NavigationMeshAsset!
    
    init?(url: URL)
    {
        do
        {
            let data = try Data(contentsOf: url)
            
            let decoder = JSONDecoder()
            asset = try decoder.decode(NavigationMeshAsset.self, from: data)
            
            setupRenderData()
        }
        catch
        {
            print("NavigationMesh", error)
            return nil
        }
    }
    
    private func setupRenderData()
    {
        let vertices = asset.verts.map({ BasicVertex(pos: $0) })
        let indices = asset.polys.reduce(into: [], { $0.append(contentsOf: $1) })
        
        vertexBuffer = Engine.device.makeBuffer(bytes: vertices,
                                                length: vertices.count * MemoryLayout<BasicVertex>.stride,
                                                options: [])

        indexBuffer = Engine.device.makeBuffer(bytes: indices,
                                               length: indices.count * MemoryLayout<UInt32>.stride,
                                               options: [])
        
        indexCount = indices.count
    }
    
    func renderWithEncoder(_ encoder: MTLRenderCommandEncoder)
    {
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: indexCount,
                                      indexType: .uint32,
                                      indexBuffer: indexBuffer,
                                      indexBufferOffset: 0)
    }
}

private struct NavigationMeshAsset: Codable
{
    let verts: [float3]
    let polys: [[UInt32]]
}

private struct BasicVertex
{
    let pos: float3
    let uv: float2 = .zero
}
