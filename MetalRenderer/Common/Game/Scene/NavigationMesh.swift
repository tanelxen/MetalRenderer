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
    
    private var selectedIndexBuffer: MTLBuffer!
    private var selectedIndicesCount: Int = 0
    
    private var unselectedIndexBuffer: MTLBuffer!
    private var unselectedIndicesCount: Int = 0
    
    private var hasUnselected = true
    private var hasSelected = false
    
    private var polyToSelect = 0
    private var selectTimer: Timer?
    
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
    
    func selectByRay(start: float3, end: float3)
    {
//        Debug.shared.addLine(start: start, end: end, color: float4(1, 1, 0, 1))
        
        for (index, poly) in asset.polys.enumerated()
        {
            let v0 = asset.verts[Int(poly[0])]
            let v1 = asset.verts[Int(poly[1])]
            let v2 = asset.verts[Int(poly[2])]
            
            let point = lineIntersectTriangle(v0: v0, v1: v1, v2: v2,
                                              start: start, end: end)
            
            if point != nil
            {
//                let trans = Transform()
//                trans.position = point
//                trans.scale = float3(repeating: 5)
//
//                Debug.shared.addCube(transform: trans, color: float4(1, 0, 1, 0.5))
                
                setSelectedPolys([index])
                break
            }
        }
    }
    
    func renderWithEncoder(_ encoder: MTLRenderCommandEncoder)
    {
        guard hasUnselected || hasSelected else { return }
        
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        var modelConstants = ModelConstants()
        
        if hasUnselected
        {
            modelConstants.color = float4(0, 1, 0, 0.6)
            encoder.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
            
            encoder.drawIndexedPrimitives(type: .triangle,
                                          indexCount: unselectedIndicesCount,
                                          indexType: .uint32,
                                          indexBuffer: unselectedIndexBuffer,
                                          indexBufferOffset: 0)
        }
        
        if hasSelected
        {
            modelConstants.color = float4(1, 0, 0, 0.6)
            encoder.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
            
            encoder.drawIndexedPrimitives(type: .triangle,
                                          indexCount: selectedIndicesCount,
                                          indexType: .uint32,
                                          indexBuffer: selectedIndexBuffer,
                                          indexBufferOffset: 0)
        }
    }
    
    private func setupRenderData()
    {
        let vertices = asset.verts.map({ BasicVertex(pos: $0) })
        let indices = asset.polys.reduce(into: [], { $0.append(contentsOf: $1) })
        
        vertexBuffer = Engine.device.makeBuffer(bytes: vertices,
                                                length: vertices.count * MemoryLayout<BasicVertex>.stride,
                                                options: [])

        selectedIndexBuffer = Engine.device.makeBuffer(bytes: [],
                                                       length: indices.count * MemoryLayout<UInt32>.stride,
                                                       options: [])
        
        unselectedIndexBuffer = Engine.device.makeBuffer(bytes: indices,
                                                         length: indices.count * MemoryLayout<UInt32>.stride,
                                                         options: [])
        
        unselectedIndicesCount = indices.count
        hasUnselected = true
        
//        DispatchQueue.main.async {
//            self.selectTimer = Timer.scheduledTimer(timeInterval: 1.0,
//                                                    target: self,
//                                                    selector: #selector(self.selectNextPoly),
//                                                    userInfo: nil,
//                                                    repeats: true)
//        }
    }
    
    @objc private func selectNextPoly()
    {
        print("selectNextPoly", polyToSelect)
        
        if polyToSelect >= asset.polys.count {
            polyToSelect = 0
        }
        
        setSelectedPolys([polyToSelect])
        
        polyToSelect += 1
    }
    
    private func setSelectedPolys(_ selectedPolys: [Int])
    {
        let selectedIndices = selectedPolys
            .reduce(into: [], {
                $0.append(contentsOf: asset.polys[$1])
            })
        
        let unselectedIndices = Array(0 ..< asset.polys.count)
            .filter({ !selectedPolys.contains($0) })
            .reduce(into: [], {
                $0.append(contentsOf: asset.polys[$1])
            })
        
        selectedIndicesCount = selectedIndices.count
        unselectedIndicesCount = unselectedIndices.count
        
        let size = MemoryLayout<UInt32>.stride
        
        memcpy(selectedIndexBuffer.contents(), selectedIndices, size * selectedIndicesCount)
        memcpy(unselectedIndexBuffer.contents(), unselectedIndices, size * unselectedIndicesCount)
        
        hasSelected = selectedIndicesCount > 0
        hasUnselected = unselectedIndicesCount > 0
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

private extension Array where Element: Hashable
{
    func difference(from other: [Element]) -> [Element]
    {
        let thisSet = Set(self)
        let otherSet = Set(other)
        
        return Array(thisSet.symmetricDifference(otherSet))
    }
}
