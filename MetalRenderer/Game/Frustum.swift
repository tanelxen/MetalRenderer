//
//  Frustum.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 19.02.2022.
//

import Foundation
import simd

class Frustum
{
    private var planes: [Plane] = []
    
    func update(with mat: matrix_float4x4)
    {
        planes = [
            normalizePlane(
                mat[3][0] + mat[0][0],
                mat[3][1] + mat[0][1],
                mat[3][2] + mat[0][2],
                mat[3][3] + mat[0][3]), // left
            
            normalizePlane(
                mat[3][0] - mat[0][0],
                mat[3][1] - mat[0][1],
                mat[3][2] - mat[0][2],
                mat[3][3] - mat[0][3]), // right
            
            normalizePlane(
                mat[3][0] - mat[1][0],
                mat[3][1] - mat[1][1],
                mat[3][2] - mat[1][2],
                mat[3][3] - mat[1][3]), // top
            
            normalizePlane(
                mat[3][0] + mat[1][0],
                mat[3][1] + mat[1][1],
                mat[3][2] + mat[1][2],
                mat[3][3] + mat[1][3]), // bottom
            
            normalizePlane(
                mat[3][0] + mat[2][0],
                mat[3][1] + mat[2][1],
                mat[3][2] + mat[2][2],
                mat[3][3] + mat[2][3]), // near
            
            normalizePlane(
                mat[3][0] - mat[2][0],
                mat[3][1] - mat[2][1],
                mat[3][2] - mat[2][2],
                mat[3][3] - mat[2][3])  // far
        ]
    }
    
    func checkPoint(_ point: float3) -> Bool
    {
        for plane in planes
        {
            let distance = plane.normal.x * point.x + plane.normal.y * point.y + plane.normal.z * point.z + plane.distance
            
            if distance <= 0 { return false }
        }

       return true
    }
    
    func checkSphere(_ point: float3, radius: Float) -> Bool
    {
        for plane in planes
        {
            let distance = plane.normal.x * point.x + plane.normal.y * point.y + plane.normal.z * point.z + plane.distance
            
            if distance <= -radius { return false }
        }

       return true
    }
    
    func checkBox(mins: float3, maxs: float3) -> Bool
    {
        // check box outside/inside of frustum
        for plane in planes
        {
            var out: Int = 0
            
            out += simd_dot(plane.normal, float3(mins.x, mins.y, mins.z)) + plane.distance < 0 ? 1 : 0
            out += simd_dot(plane.normal, float3(maxs.x, mins.y, mins.z)) + plane.distance < 0 ? 1 : 0
            out += simd_dot(plane.normal, float3(mins.x, maxs.y, mins.z)) + plane.distance < 0 ? 1 : 0
            out += simd_dot(plane.normal, float3(maxs.x, maxs.y, mins.z)) + plane.distance < 0 ? 1 : 0
            
            out += simd_dot(plane.normal, float3(mins.x, mins.y, maxs.z)) + plane.distance < 0 ? 1 : 0
            out += simd_dot(plane.normal, float3(maxs.x, mins.y, maxs.z)) + plane.distance < 0 ? 1 : 0
            out += simd_dot(plane.normal, float3(mins.x, maxs.y, maxs.z)) + plane.distance < 0 ? 1 : 0
            out += simd_dot(plane.normal, float3(maxs.x, maxs.y, maxs.z)) + plane.distance < 0 ? 1 : 0
            
            if out == 8 { return false }
        }

        return true
    }
    
    func checkAABB(min: float3, max: float3) -> Bool
    {
        // check box outside/inside of frustum
        for plane in planes
        {
            var out: Int = 0
            
            out += testAABBPlane(min: min, max: max, plane: plane) ? 1 : 0

            if out == 8 { return true }
        }

        return false
    }
    
    func checkMesh(vertices: [float3]) -> Bool
    {
        for vertex in vertices
        {
            if checkPoint(vertex)
            {
                return true
            }
        }
        
        return false
    }
    
    private func normalizePlane(_ A: Float, _ B: Float, _ C: Float, _ D: Float) -> Plane
    {
        let nf: Float = 1.0 / sqrt(A * A + B * B + C * C)

        return Plane(normal: float3(nf * A, nf * B, nf * C), distance: nf * D)
    }
    
//    private struct Plane
//    {
//        var normal: float3
//        var distance: Float
//    }
}
