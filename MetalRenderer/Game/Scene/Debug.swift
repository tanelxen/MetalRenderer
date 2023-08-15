//
//  Debug.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 15.08.2023.
//

import MetalKit

final class Debug
{
    private struct Line
    {
        let start: float3
        let end: float3
        let color: float3
    }
    
    private struct Cube
    {
        let modelMatrix: matrix_float4x4
        let color: float3
    }
    
    private var lines: [Line] = []
    private var cubes: [Cube] = []
    
    private let cubeShape = CubeShape(mins: .zero, maxs: .one)
    
    func addLine(start: float3, end: float3, color: float3)
    {
        let line = Line(start: start, end: end, color: color)
        lines.append(line)
    }
    
    func addCube(center: float3, size: float3, color: float3)
    {
        let transform = Transform()
        transform.position = center
        transform.scale = size
        transform.updateModelMatrix()
        
        let cube = Cube(modelMatrix: transform.matrix, color: color)
        cubes.append(cube)
    }
    
    func render(with encoder: MTLRenderCommandEncoder?)
    {
        for line in lines
        {
            var modelConstants = ModelConstants()
            modelConstants.color = line.color

            encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)

            var vertices = [line.start, line.end]
            encoder?.setVertexBytes(&vertices, length: MemoryLayout<float3>.stride * 2, index: 0)

            encoder?.drawPrimitives(type: .line, vertexStart: 0, vertexCount: 2)
        }
        
        for cube in cubes
        {
            var modelConstants = ModelConstants()
            modelConstants.color = cube.color
            modelConstants.modelMatrix = cube.modelMatrix
            
            encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
            
            cubeShape.render(with: encoder)
        }
    }
}
