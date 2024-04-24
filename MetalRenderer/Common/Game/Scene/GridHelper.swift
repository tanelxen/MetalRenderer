//
//  GridHelper.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 22.04.2024.
//

import Metal
import simd

final class GridHelper
{
    let gridSize: Float = 16
    
    private var isCreationMode = false
    private var isPlaneDrawn = false
    private var height: Float = 0
    private var startPoint: float3?
    private let cube = HelperCube()
    
    var viewport: Viewport?
    
    weak var scene: BrushScene?
    
    func update()
    {
        guard let viewport = viewport else { return }
        
        isCreationMode = Keyboard.isKeyPressed(.c)
        
        if isCreationMode
        {
            let ray = viewport.mousePositionInWorld()
            
            if let point = intersection(ray: ray)?.snapped(gridSize)
            {
                if let start = startPoint
                {
                    if Mouse.IsMouseButtonPressed(.left)
                    {
                        let x = min(start.x, point.x)
                        let y = min(start.y, point.y)
                        let width = abs(start.x - point.x) + gridSize
                        let height = abs(start.y - point.y) + gridSize
                        
                        cube.transform.position = float3(x, y, 0)
                        cube.transform.scale = float3(width, height, 0)
                        isPlaneDrawn = true
                    }
                    else if isPlaneDrawn
                    {
                        height -= Mouse.getDY()
                        cube.transform.scale.z = snap(value: height, step: gridSize)
                    }
                }
                else
                {
                    cube.transform.position = point
                    cube.transform.scale = float3(gridSize, gridSize, 0)
                    
                    if Mouse.IsMouseButtonPressed(.left)
                    {
                        startPoint = point
                        isPlaneDrawn = false
                        height = gridSize
                    }
                }
            }
        }
        else
        {
            if isPlaneDrawn, cube.transform.scale.z > 0
            {
                scene?.addBrush(position: cube.transform.position, size: cube.transform.scale)
            }
            
            startPoint = nil
            isPlaneDrawn = false
            height = gridSize
        }
    }
    
    func render(with encoder: MTLRenderCommandEncoder?)
    {
        
        
        if isCreationMode
        {
            cube.render(with: encoder)
        }
    }
    
    private func intersection(ray: Ray) -> float3?
    {
        let normal = float3(0, 0, 1)
        let distance: Float = 0
        
        let dotProduct = dot(ray.direction, normal)
        
        if abs(dotProduct) < 0.000001 { return nil }
        
        let t = (distance - dot(ray.origin, normal)) / dotProduct
        
        if t < 0 { return nil }
        
        return (ray.origin + ray.direction * t) * float3(1, 1, 0)
        
//        return round(result * 1000) / 1000
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
    
    init(_ x: Float, _ y: Float)
    {
        self.pos = float3(x, y, 0)
        self.uv = .zero
    }
}

final class HelperCube
{
    private var minBounds: float3 = .zero
    private var maxBounds: float3 = .one
    
    private var vertices: [BasicVertex] = []
    private var indicies: [UInt16] = []
    
    private var verticesBuffer: MTLBuffer!
    private var indiciesBuffer: MTLBuffer!
    
    let transform = Transform()

    init()
    {
        transform.scale = float3(16, 16, 16)
        
        vertices = [
            BasicVertex(minBounds.x, minBounds.y, minBounds.z, 0, 0),  // Back     Right   Bottom      0
            BasicVertex(maxBounds.x, minBounds.y, minBounds.z, 1, 0),  // Front    Right   Bottom      1
            BasicVertex(minBounds.x, maxBounds.y, minBounds.z, 0, 1),  // Back     Left    Bottom      2
            BasicVertex(maxBounds.x, maxBounds.y, minBounds.z, 1, 1),  // Front    Left    Bottom      3
            
            BasicVertex(minBounds.x, minBounds.y, maxBounds.z, 0, 0),  // Back     Right   Top         4
            BasicVertex(maxBounds.x, minBounds.y, maxBounds.z, 1, 0),  // Front    Right   Top         5
            BasicVertex(minBounds.x, maxBounds.y, maxBounds.z, 0, 1),  // Back     Left    Top         6
            BasicVertex(maxBounds.x, maxBounds.y, maxBounds.z, 1, 0)   // Front    Left    Top         7
        ]
        
        indicies = [
            //Top
            4, 6, 5,
            5, 6, 7,
            
            //Bottom
            2, 0, 3,
            3, 0, 1,
            
            //Back
            0, 2, 4,
            4, 2, 6,
            
            //Front
            3, 1, 7,
            7, 1, 5,
            
            //Right
            1, 0, 5,
            5, 0, 4,
            
            //Left
            2, 3, 6,
            6, 3, 7,
        ]
        
        verticesBuffer = Engine.device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<BasicVertex>.stride * vertices.count,
            options: []
        )
        
        indiciesBuffer = Engine.device.makeBuffer(
            bytes: indicies,
            length: MemoryLayout<UInt16>.size * indicies.count,
            options: []
        )
    }
    
    func render(with encoder: MTLRenderCommandEncoder?)
    {
        guard verticesBuffer != nil else { return }
        
        transform.updateModelMatrix()
        
        var modelConstants = ModelConstants()
        modelConstants.color = float4(1, 0, 1, 0.3)
        modelConstants.modelMatrix = transform.matrix
        
        encoder?.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        encoder?.setVertexBuffer(verticesBuffer, offset: 0, index: 0)

        encoder?.drawIndexedPrimitives(type: .triangle,
                                       indexCount: indicies.count,
                                       indexType: .uint16,
                                       indexBuffer: indiciesBuffer,
                                       indexBufferOffset: 0)
    }
}

func snap(value: Float, step: Float) -> Float {
    return floor(value / step) * step
}

func snap(value: float3, step: Float) -> float3 {
    return floor(value / step) * step
}

private extension float3
{
    func snapped(_ step: Float) -> float3
    {
        return snap(value: self, step: step)
    }
}
