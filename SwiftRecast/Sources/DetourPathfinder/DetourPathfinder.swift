//
//  File.swift
//  
//
//  Created by Fedor Artemenkov on 13/4/24.
//

import Foundation
import CDetour
import simd

public class DetourPathfinder
{
    private var m_navMesh: OpaquePointer?
    private var m_navQuery: OpaquePointer?
    
    public init() { }
    
    public func load(from data: Data)
    {
        let bytes = [UInt8](data)
        let size = data.count
        
        m_navMesh = create_navmesh(bytes, size)

        if m_navMesh != nil
        {
            m_navQuery = create_query(m_navMesh)
        }
    }
    
    public func findPath(start: simd_float3, end: simd_float3, halfExtents: simd_float3) -> [simd_float3]
    {
        guard m_navQuery != nil else { return [] }
        
        let result = find_path(m_navQuery, start, end, halfExtents)

        let outputFloats = UnsafeBufferPointer<Float>(
            start: result.points,
            count: Int(result.count) * 3
        )
        
        let array = [Float](outputFloats)
        
        let path = stride(from: 0, to: array.count, by: 3).map {
            simd_float3(array[$0], array[$0+1], array[$0+2])
        }
        
        return path
    }
    
    public func randomPath(from start: simd_float3, halfExtents: simd_float3) -> [simd_float3]
    {
        guard m_navQuery != nil else { return [] }
        
        let result = random_path(m_navQuery, start, halfExtents)

        let outputFloats = UnsafeBufferPointer<Float>(
            start: result.points,
            count: Int(result.count) * 3
        )
        
        let array = [Float](outputFloats)
        
        let path = stride(from: 0, to: array.count, by: 3).map {
            simd_float3(array[$0], array[$0+1], array[$0+2])
        }
        
        return path
    }
    
    public func simpleMesh() -> (vertices: [simd_float3], polys: [Int])
    {
        let mesh = get_simple_mesh(m_navMesh)
        
        guard mesh.num_vertices > 0, mesh.num_indices > 0
        else {
            return ([], [])
        }
        
        let coordsBuffer = UnsafeBufferPointer<Float>(
            start: mesh.vertices,
            count: Int(mesh.num_vertices)
        )
        
        let indicesBuffer = UnsafeBufferPointer<Int32>(
            start: mesh.indices,
            count: Int(mesh.num_indices)
        )
        
        let coords = [Float](coordsBuffer)
        let indices = ([Int32](indicesBuffer)).map({ Int($0) })
        
        let vertices = stride(from: 0, to: coords.count, by: 3).map {
            simd_float3(coords[$0], coords[$0+1], coords[$0+2])
        }
        
        if let vertices = mesh.vertices {
            free(vertices)
        }
        
        if let indices = mesh.indices {
            free(indices)
        }
        
        return (vertices, indices)
    }
    
    deinit
    {
        destroy_query(m_navQuery)
        destroy_navmesh(m_navMesh)
    }
}
