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
    
    private var selectedIndexBuffer: MTLBuffer!
    private var selectedIndicesCount: Int = 0
    
    private var unselectedIndexBuffer: MTLBuffer!
    private var unselectedIndicesCount: Int = 0
    
    private var hasUnselected = true
    private var hasSelected = false
    
    private var polyToSelect = 0
    private var selectTimer: Timer?
    
    private var asset: NavigationMeshAsset!
    
    private var links: [[Int]] = []
    private var costs: [[Float]] = []
    
    struct Node
    {
        var position: float3 = .zero
        var neighbors: [(Float, Int)] = []
    }
    
    private var waypoints: [Node] = []
    
    var pathfinder: DetourPathfinder?
    
    var isDebugDrawable = true
    
    init?(data: Data)
    {
        do
        {
            let decoder = JSONDecoder()
            asset = try decoder.decode(NavigationMeshAsset.self, from: data)
            
            links = buildNeighborIndices(triangleIndices: asset.polys)
            costs = buildDistances(verts: asset.verts, links: links)
            
            waypoints = [Node](repeating: Node(), count: asset.verts.count)
            
            for i in 0 ..< waypoints.count
            {
                waypoints[i].position = asset.verts[i]
                waypoints[i].neighbors = Array(zip(costs[i], links[i]))
            }
            
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
        
        Debug.shared.clear()
        
        for (index, poly) in asset.polys.enumerated()
        {
            let v0 = asset.verts[poly[0]]
            let v1 = asset.verts[poly[1]]
            let v2 = asset.verts[poly[2]]
            
            let point = lineIntersectTriangle(v0: v0, v1: v1, v2: v2,
                                              start: start, end: end)
            
            if point != nil
            {
                let offset = float3(0, 0, 0.01)
                Debug.shared.addLine(start: point! + offset, end: v0 + offset, color: float4(1, 1, 0, 1))
                Debug.shared.addLine(start: point! + offset, end: v1 + offset, color: float4(1, 1, 0, 1))
                Debug.shared.addLine(start: point! + offset, end: v2 + offset, color: float4(1, 1, 0, 1))
                
                for vert in poly
                {
                    let trans = Transform()
                    trans.position = asset.verts[vert]
                    trans.scale = float3(repeating: 5)

                    Debug.shared.addCube(transform: trans, color: float4(1, 1, 0, 0.5))
                }
                
                var neighbors = links[poly[0]] + links[poly[1]] + links[poly[2]]
                neighbors = Array(Set(neighbors)).filter({ !poly.contains($0) })
                
                for neighbor in neighbors
                {
                    let trans = Transform()
                    trans.position = asset.verts[neighbor]
                    trans.scale = float3(repeating: 3)

                    Debug.shared.addCube(transform: trans, color: float4(1, 0, 1, 0.5))
                }
                
                setSelectedPolys([index])
                break
            }
        }
    }
    
    func renderWithEncoder(_ encoder: MTLRenderCommandEncoder)
    {
        guard isDebugDrawable else { return }
        guard hasUnselected || hasSelected else { return }
        
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        var modelConstants = ModelConstants()
        
        if hasUnselected
        {
            modelConstants.color = float4(0, 1, 0, 0.6)
            encoder.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
            
//            encoder.setTriangleFillMode(.lines)
            encoder.drawIndexedPrimitives(type: .triangle,
                                          indexCount: unselectedIndicesCount,
                                          indexType: .uint16,
                                          indexBuffer: unselectedIndexBuffer,
                                          indexBufferOffset: 0)
            
//            encoder.setTriangleFillMode(.fill)
        }
        
        if hasSelected
        {
            modelConstants.color = float4(1, 0, 0, 0.6)
            encoder.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
            
            encoder.drawIndexedPrimitives(type: .triangle,
                                          indexCount: selectedIndicesCount,
                                          indexType: .uint16,
                                          indexBuffer: selectedIndexBuffer,
                                          indexBufferOffset: 0)
        }
    }
    
    private func setupRenderData()
    {
        let vertices = asset.verts.map({ BasicVertex(pos: $0) })
        let indices = asset.polys.flatMap({ $0 }).map({ UInt16($0) })
        
        vertexBuffer = Engine.device.makeBuffer(bytes: vertices,
                                                length: vertices.count * MemoryLayout<BasicVertex>.stride,
                                                options: [])

        selectedIndexBuffer = Engine.device.makeBuffer(bytes: [],
                                                       length: indices.count * MemoryLayout<UInt16>.stride,
                                                       options: [])
        
        unselectedIndexBuffer = Engine.device.makeBuffer(bytes: indices,
                                                         length: indices.count * MemoryLayout<UInt16>.stride,
                                                         options: [])
        
        unselectedIndicesCount = indices.count
        hasUnselected = true
    }
    
    private func setSelectedPolys(_ selectedPolys: [Int])
    {
        let selectedIndices = selectedPolys
            .flatMap { asset.polys[$0] }
            .map { UInt16($0) }
        
        let unselectedIndices = Array(0 ..< asset.polys.count)
            .filter({ !selectedPolys.contains($0) })
            .flatMap { asset.polys[$0] }
            .map { UInt16($0) }
        
        selectedIndicesCount = selectedIndices.count
        unselectedIndicesCount = unselectedIndices.count
        
        let size = MemoryLayout<UInt16>.stride
        
        memcpy(selectedIndexBuffer.contents(), selectedIndices, size * selectedIndicesCount)
        memcpy(unselectedIndexBuffer.contents(), unselectedIndices, size * unselectedIndicesCount)
        
        hasSelected = selectedIndicesCount > 0
        hasUnselected = unselectedIndicesCount > 0
    }
    
    // Функция для построения списка индексов соседних вершин
    private func buildNeighborIndices(triangleIndices: [[Int]]) -> [[Int]]
    {
        let count = triangleIndices.flatMap { $0 }.max()! + 1
        var neighborIndices = [[Int]](repeating: [], count: count)

        // Хэш-таблица для быстрого поиска соседей по индексу вершины
        var vertexNeighbors = [Int: Set<Int>]()

        // Пройдемся по каждому треугольнику
        for triangle in triangleIndices
        {
            // Для каждой вершины треугольника добавим индексы остальных вершин треугольника в ее список соседей
            for vertexIndex in triangle
            {
                let otherVertexIndices = triangle.filter { $0 != vertexIndex }
                
                if var neighbors = vertexNeighbors[vertexIndex]
                {
                    // Добавим новых соседей
                    neighbors.formUnion(otherVertexIndices)
                    vertexNeighbors[vertexIndex] = neighbors
                }
                else
                {
                    vertexNeighbors[vertexIndex] = Set(otherVertexIndices)
                }
            }
        }

        // Преобразуем результаты из хэш-таблицы в массив
        for (vertexIndex, neighborsSet) in vertexNeighbors {
            neighborIndices[vertexIndex] = Array(neighborsSet)
        }

        return neighborIndices
    }
    
    private func buildDistances(verts: [float3], links: [[Int]]) -> [[Float]]
    {
        let count = verts.count
        var distances = [[Float]](repeating: [], count: count)
        
        for currentVertIndex in 0 ..< count
        {
            let currentVert = verts[currentVertIndex]
            let neighbors = links[currentVertIndex]
            
            distances[currentVertIndex] = [Float](repeating: 0, count: neighbors.count)
            
            for (neighborIndex, neighborVertIndex) in neighbors.enumerated()
            {
                let neighborVert = verts[neighborVertIndex]
                distances[currentVertIndex][neighborIndex] = length(neighborVert - currentVert)
            }
        }
        
        return distances
    }
}

extension NavigationMesh
{
    func makeRoute(from startPos: float3, to endPos: float3) -> [float3]
    {
        guard let pathfinder = self.pathfinder else {
            print("Have no Detour Pathfinder!!!")
            return []
        }
        
        let spos = float3(startPos.x, startPos.z, -startPos.y)
        let epos = float3(endPos.x, endPos.z, -endPos.y)
        let ext = float3(0, 56, 0)
        
        let path = pathfinder.findPath(start: spos, end: epos, halfExtents: ext)
        
        return path.map { float3($0.x, -$0.z, $0.y) }
    }
    
    func makeRandomRoute(from startPos: float3) -> [float3]
    {
        guard let pathfinder = self.pathfinder else {
            print("Have no Detour Pathfinder!!!")
            return []
        }
        
        let spos = float3(startPos.x, startPos.z, -startPos.y)
        let ext = float3(0, 56, 0)
        
        let path = pathfinder.randomPath(from: spos, halfExtents: ext)
        
        return path.map { float3($0.x, -$0.z, $0.y) }
    }
}

private struct NavigationMeshAsset: Codable
{
    let verts: [float3]
    let polys: [[Int]]
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

private struct Queue<T>
{
    private var elements: [T] = []

    mutating func push(_ value: T)
    {
        elements.append(value)
    }

    mutating func pop() -> T?
    {
        guard !elements.isEmpty else { return nil }
        return elements.removeFirst()
    }

    var head: T? {
        return elements.first
    }

    var tail: T? {
        return elements.last
    }
}
