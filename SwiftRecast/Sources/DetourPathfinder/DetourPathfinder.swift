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
    
    deinit
    {
        destroy_query(m_navQuery)
        destroy_navmesh(m_navMesh)
    }
}
