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
        let color: float4
    }
    
    private struct Shape
    {
        let transform: Transform
        let color: float4
        
        /*
         value in seconds
         -1 - draw eternaly
          0 - draw one frame
         */
        var lifespan: Float
    }
    
    private var lines: [Line] = []
    private var cubes: [Shape] = []
    private var quads: [Shape] = []
    
    private let cubeShape = CubeShape(mins: .zero, maxs: .one)
    private let quadShape = QuadShape(mins: .zero, maxs: .one)
    
    static let shared = Debug()
    
    private let maxInstances = 10000
    
    private var cubesConstantsBuffer: MTLBuffer!
    private var quadsConstantsBuffer: MTLBuffer!
    
    init()
    {
        cubesConstantsBuffer = Engine.device.makeBuffer(length: ModelConstants.stride(maxInstances), options: [])
        quadsConstantsBuffer = Engine.device.makeBuffer(length: ModelConstants.stride(maxInstances), options: [])
    }
    
    func addLine(start: float3, end: float3, color: float4)
    {
        let line = Line(start: start, end: end, color: color)
        lines.append(line)
    }
    
    func addCube(transform: Transform, color: float4, lifespan: Float = -1)
    {
        let cube = Shape(transform: transform, color: color, lifespan: lifespan)
        cubes.append(cube)
    }
    
    func addQuad(transform: Transform, color: float4, lifespan: Float = -1)
    {
        let quad = Shape(transform: transform, color: color, lifespan: lifespan)
        quads.append(quad)
    }
    
    func render(with encoder: MTLRenderCommandEncoder?)
    {
        for line in lines
        {
            var modelConstants = ModelConstants()
            modelConstants.color = line.color

            encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)

            var vertices = [
                BasicVertex(line.start.x, line.start.y, line.start.z, 0, 0),
                BasicVertex(line.end.x, line.end.y, line.end.z, 0, 0)
            ]
            
            encoder?.setVertexBytes(&vertices, length: MemoryLayout<BasicVertex>.stride * 2, index: 0)

            encoder?.drawPrimitives(type: .line, vertexStart: 0, vertexCount: 2)
        }
    }
    
    func renderInstanced(with encoder: MTLRenderCommandEncoder?)
    {
        drawCubes(with: encoder)
        drawQuads(with: encoder)
    }
    
    private func drawCubes(with encoder: MTLRenderCommandEncoder?)
    {
        guard !cubes.isEmpty else { return }
        
        var pointer = cubesConstantsBuffer.contents().bindMemory(to: ModelConstants.self, capacity: maxInstances)
        
        var instancesCount: Int = 0
        
        for (index, cube) in cubes.enumerated()
        {
            guard index < maxInstances else { break }
            
            var modelConstants = ModelConstants()
            modelConstants.color = cube.color

            cube.transform.updateModelMatrix()
            modelConstants.modelMatrix = cube.transform.matrix

            pointer.pointee = modelConstants
            pointer = pointer.advanced(by: 1)
            
            instancesCount += 1
        }
        
        cubes.removeAll(where: { $0.lifespan == 0 })
        
        guard instancesCount > 0 else { return }
        
        encoder?.setVertexBuffer(cubesConstantsBuffer, offset: 0, index: 2)
        
        cubeShape.render(with: encoder, instanceCount: instancesCount)
    }
    
    private func drawQuads(with encoder: MTLRenderCommandEncoder?)
    {
        guard !quads.isEmpty else { return }
        
        var pointer = quadsConstantsBuffer.contents().bindMemory(to: ModelConstants.self, capacity: maxInstances)
        
        for (index, quad) in quads.enumerated()
        {
            guard index < maxInstances else { break }
            
            var modelConstants = ModelConstants()
            modelConstants.color = quad.color

            quad.transform.updateModelMatrix()
            modelConstants.modelMatrix = quad.transform.matrix

            pointer.pointee = modelConstants
            pointer = pointer.advanced(by: 1)
        }
        
        encoder?.setVertexBuffer(quadsConstantsBuffer, offset: 0, index: 2)
        
        quadShape.render(with: encoder!, instanceCount: quads.count)
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
}
