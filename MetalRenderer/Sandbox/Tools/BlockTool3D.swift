//
//  BlockTool.swift
//  Sandbox
//
//  Created by Fedor Artemenkov on 31.05.2024.
//

import Foundation
import Metal
import simd

final class BlockTool3D
{
    private let viewport: Viewport
    private let cube = Cube()
    
    private var gridSize: Float = 8
    private var dragOrigin: float3?
    
    private var isCreationMode = false
    private var isPlaneDrawn = false
    private var height: Float = 0
    private var startPoint: float3?
    
    private var downMouseTimestemp: Date?
    private var downMousePos: float2?
    
    // Projection plane
    private var plane: Plane {
        Plane(normal: viewport.viewType.normal, distance: 0)
    }
    
    init(viewport: Viewport)
    {
        self.viewport = viewport
        
    }
    
    func update()
    {
        if Mouse.IsMouseButtonPressed(.left) && Keyboard.isKeyPressed(.shift)
        {
            if downMousePos == nil
            {
                downMousePos = Mouse.getMouseWindowPosition()
                downMouseTimestemp = Date()
            }
        }
        else
        {
            if let oldPos = downMousePos, let timestemp = downMouseTimestemp
            {
                let newPos = Mouse.getMouseWindowPosition()
                let delta = length(newPos - oldPos)
                
                let timeInterval = Date().timeIntervalSince(timestemp)
                
                if timeInterval < 0.3, delta < gridSize * 0.5
                {
                    print("Select click")
                    
                    let ray = viewport.mousePositionInWorld()
                    BrushScene.current.select(by: ray)
                }
                
                downMouseTimestemp = nil
                downMousePos = nil
            }
        }
        
//        let ray = viewport.mousePositionInWorld()
//
//        guard var point = intersection(ray: ray, plane: plane)
//        else {
//            return
//        }
//
//        // Sometimes we get coordinates little bit less zero
//        point = round(point * 10) / 10
//
//        point = floor(point / gridSize) * gridSize
//
//        isCreationMode = Keyboard.isKeyPressed(.c)
//
//        if isCreationMode
//        {
//            if let start = startPoint
//            {
//                if Mouse.IsMouseButtonPressed(.left)
//                {
//                    let x = min(start.x, point.x)
//                    let z = min(start.z, point.z)
//                    let width = abs(start.x - point.x) + gridSize
//                    let depth = abs(start.z - point.z) + gridSize
//
//                    cube.transform.position = float3(x, 0, z)
//                    cube.transform.scale = float3(width, 0, depth)
//                    isPlaneDrawn = true
//                }
//                else if isPlaneDrawn
//                {
//                    height -= Mouse.getDY()
//                    cube.transform.scale.y = floor(height / gridSize) * gridSize
//                }
//            }
//            else
//            {
//                cube.transform.position = point
//                cube.transform.scale = float3(gridSize, gridSize, gridSize)
//
//                if Mouse.IsMouseButtonPressed(.left)
//                {
//                    startPoint = point
//                    isPlaneDrawn = false
//                    height = gridSize
//                }
//            }
//        }
//        else
//        {
//            if isPlaneDrawn, cube.transform.scale.y > 0
//            {
//                BrushScene.current.addBrush(position: cube.transform.position, size: cube.transform.scale)
//            }
//
//            startPoint = nil
//            isPlaneDrawn = false
//            height = gridSize
//        }
    }
    
    func draw(with renderer: ForwardRenderer)
    {
        if isCreationMode
        {
            cube.render(with: renderer)
        }
    }
}

private struct BasicVertex
{
    let pos: float3
    let uv: float2 = .zero
    
    init(_ x: Float, _ y: Float, _ z: Float)
    {
        self.pos = float3(x, y, z)
    }
}

private final class Cube
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
        vertices = [
            BasicVertex(minBounds.x, minBounds.y, minBounds.z),  // Back     Right   Bottom      0
            BasicVertex(maxBounds.x, minBounds.y, minBounds.z),  // Front    Right   Bottom      1
            BasicVertex(minBounds.x, maxBounds.y, minBounds.z),  // Back     Left    Bottom      2
            BasicVertex(maxBounds.x, maxBounds.y, minBounds.z),  // Front    Left    Bottom      3
            
            BasicVertex(minBounds.x, minBounds.y, maxBounds.z),  // Back     Right   Top         4
            BasicVertex(maxBounds.x, minBounds.y, maxBounds.z),  // Front    Right   Top         5
            BasicVertex(minBounds.x, maxBounds.y, maxBounds.z),  // Back     Left    Top         6
            BasicVertex(maxBounds.x, maxBounds.y, maxBounds.z)   // Front    Left    Top         7
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
    
    func render(with renderer: ForwardRenderer)
    {
        guard verticesBuffer != nil else { return }
        
        var renderItem = RenderItem(technique: .basic)
        renderItem.cullMode = .back
        renderItem.tintColor = [1, 0, 1, 0.3]
        
        renderItem.transform = transform
        
        renderItem.primitiveType = .triangle
        renderItem.vertexBuffer = verticesBuffer
        
        renderItem.indexBuffer = indiciesBuffer
        renderItem.numIndices = indicies.count
        
        renderer.add(item: renderItem)
    }
}
