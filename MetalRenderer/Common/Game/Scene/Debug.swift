//
//  Debug.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 15.08.2023.
//

import Metal

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
        let transform: Transform
        let color: float3
    }
    
    private var lines: [Line] = []
    private var cubes: [Cube] = []
    
    private let cubeShape = CubeShape(mins: .zero, maxs: .one)
    
    static let shared = Debug()
    
    private let maxCubes = 1000
    
    private var cubesConstantsBuffer: MTLBuffer!
    
    init()
    {
        cubesConstantsBuffer = Engine.device.makeBuffer(length: ModelConstants.stride(maxCubes), options: [])
    }
    
    func addLine(start: float3, end: float3, color: float3)
    {
        let line = Line(start: start, end: end, color: color)
        lines.append(line)
    }
    
    func addCube(transform: Transform, color: float3)
    {
        let cube = Cube(transform: transform, color: color)
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
    }
    
    func renderInstanced(with encoder: MTLRenderCommandEncoder?)
    {
        guard !cubes.isEmpty else { return }
        
        var pointer = cubesConstantsBuffer.contents().bindMemory(to: ModelConstants.self, capacity: maxCubes)
        
        for cube in cubes
        {
            var modelConstants = ModelConstants()
            modelConstants.color = cube.color

            cube.transform.updateModelMatrix()
            modelConstants.modelMatrix = cube.transform.matrix

            pointer.pointee = modelConstants
            pointer = pointer.advanced(by: 1)
        }
        
        encoder?.setVertexBuffer(cubesConstantsBuffer, offset: 0, index: 2)
        
        cubeShape.render(with: encoder, instanceCount: cubes.count)
    }
}
