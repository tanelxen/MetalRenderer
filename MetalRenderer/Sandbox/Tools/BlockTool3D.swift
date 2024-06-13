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
    
    private let transform = Transform()
    private let previewShape = MTKGeometry(.boxWired)
    
    private var gridSize: Float = 8
    
    private var downMouseTimestemp: Date?
    
    private var isStartedDraw = false
    private var isPlaneDrawn = false
    private var startPoint: float3?
    private var startPoint2: float3?
    
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
            
            if isPlaneDrawn, let start = startPoint2
            {
                let normal = viewport.camera!.transform.rotation.forward
                let distance = dot(normal, start)
                let plane2 = Plane(normal: normal, distance: distance)
                
                guard var point = intersection(ray: ray, plane: plane2)
                else {
                    return
                }
                
                point = floor(point / gridSize) * gridSize
                
                let y = min(start.y, point.y)
                let height = abs(start.y - point.y) + gridSize
                
//                height -= Mouse.getDY()
//                transform.scale.y = floor(height / gridSize) * gridSize
                
                transform.position.y = y
                transform.scale.y = height
            }
            else
            {
                guard var point = intersection(ray: ray, plane: plane)
                else {
                    return
                }
                
                point = floor(point / gridSize) * gridSize
                
                let x = min(start.x, point.x)
//                let y = min(start.y, point.y)
                let z = min(start.z, point.z)
                
                let width = abs(start.x - point.x) + gridSize
//                let height = abs(start.y - point.y) + gridSize
                let depth = abs(start.z - point.z) + gridSize
                
                transform.position = float3(x, 0, z)
                transform.scale = float3(width, 0, depth)
            }
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
        isPlaneDrawn = false
        startPoint = nil
        startPoint2 = nil
    }
    
    private func processClick()
    {
        if isStartedDraw
        {
            // Finish drawing
            if isPlaneDrawn
            {
                World.current.addBrush(position: transform.position, size: transform.scale)
                reset()
            }
            else
            {
                isPlaneDrawn = true
                
                let ray = viewport.mousePositionInWorld()
                
                guard let point = intersection(ray: ray, plane: plane)
                else {
                    return
                }
                
                startPoint2 = floor(point / gridSize) * gridSize
            }
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
