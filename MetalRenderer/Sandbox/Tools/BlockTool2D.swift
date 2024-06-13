//
//  BlockTool2D.swift
//  Sandbox
//
//  Created by Fedor Artemenkov on 31.05.2024.
//

import Foundation
import Metal
import simd

final class BlockTool2D
{
    private let viewport: Viewport
    
    private let transform = Transform()
    private let previewShape = MTKGeometry(.boxWired)
    
    private var gridSize: Float = 8
    
    private var downMouseTimestemp: Date?
    
    private var isStartedDraw = false
    private var startPoint: float3?
    
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
        if Keyboard.isKeyPressed(.escape)
        {
            reset()
            return
        }
        
        if Mouse.IsMouseButtonPressed(.left)
        {
            downMouseTimestemp = Date()
        }
        else if let timestemp = downMouseTimestemp
        {
            let timeInterval = Date().timeIntervalSince(timestemp)
            
            if timeInterval < 0.2
            {
                processClick()
            }
            
            downMouseTimestemp = nil
        }
        
        // Update preview size
        if isStartedDraw, let start = startPoint
        {
            let ray = viewport.mousePositionInWorld()
            
            guard var point = intersection(ray: ray, plane: plane)
            else {
                return
            }
            
            point = floor(point / gridSize) * gridSize
            
            let x = min(start.x, point.x)
            let y = min(start.y, point.y)
            let z = min(start.z, point.z)
            
            let width = abs(start.x - point.x) + gridSize
            let height = abs(start.y - point.y) + gridSize
            let depth = abs(start.z - point.z) + gridSize
            
            transform.position = float3(x, y, z)
            transform.scale = float3(width, height, depth)
        }
    }
    
    func draw(with renderer: Renderer)
    {
        if isStartedDraw
        {
            var renderItem = RenderItem(mtkMesh: previewShape)

            renderItem.tintColor = [1, 1, 1, 1]
            renderItem.isSupportLineMode = false

            renderItem.transform.position = transform.position + transform.scale * 0.5
            renderItem.transform.scale = transform.scale

            renderer.add(item: renderItem)
        }
    }
    
    func reset()
    {
        downMouseTimestemp = nil
        isStartedDraw = false
        startPoint = nil
    }
    
    private func processClick()
    {
        // Finish drawing
        if isStartedDraw
        {
            World.current.addBrush(position: transform.position, size: transform.scale)
            reset()
        }
        else
        {
            let ray = viewport.mousePositionInWorld()
            
            if var point = intersection(ray: ray, plane: plane)
            {
                point = floor(point / gridSize) * gridSize
                
                transform.position = point
                transform.scale = float3(gridSize, gridSize, gridSize)
                
                startPoint = point
                isStartedDraw = true
            }
        }
    }
}

private enum Mode
{
    case select
    case create
}
