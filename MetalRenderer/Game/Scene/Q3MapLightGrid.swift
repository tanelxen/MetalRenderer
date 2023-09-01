//
//  Q3MapLightGrid.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.08.2023.
//

import simd

final class Q3MapLightGrid
{
    private var maxs: float3 = .zero
    private var mins: float3 = .zero
    
    private var lightVolSizeX: Float = 0
    private var lightVolSizeY: Float = 0
    private var lightVolSizeZ: Float = 0
    
    private var ambients: [float3] = []
    
    struct ColorDistance {
        let color: float3
        let distance: Float
    }
    
    init(minBounds: float3, maxBounds: float3, colors: [float3])
    {
        mins = minBounds
        maxs = maxBounds
        
        lightVolSizeX = floor(maxs.x / 64) - ceil(mins.x / 64) + 1.0
        lightVolSizeY = floor(maxs.y / 64) - ceil(mins.y / 64) + 1.0
        lightVolSizeZ = floor(maxs.z / 128) - ceil(mins.z / 128) + 1.0
        
        ambients = colors
        
//        for (index, color) in ambients.enumerated()
//        {
//            if color == .zero { continue }
//
//            let transform = Transform()
//            transform.position = positionForCell(at: Float(index))
//            transform.scale = float3(64, 64, 128)
//
//            Debug.shared.addCube(transform: transform, size: .zero, color: color)
//        }
    }
    
    func ambient(at point: float3) -> float3
    {
        guard ambients.count > 0 else { return .zero }
        
        let centerCell = cellForPoint(point)
        
        var leftCell = centerCell
        leftCell.y += 1
        
        var rightCell = centerCell
        rightCell.y -= 1
        
        var forwardCell = centerCell
        forwardCell.x += 1
        
        var backCell = centerCell
        backCell.x -= 1
        
        var topCell = centerCell
        topCell.z += 1
        
        var bottomCell = centerCell
        bottomCell.z -= 1
        
        let cells = [
            colorDistanceFor(cell: centerCell, point: point),
            colorDistanceFor(cell: leftCell, point: point),
            colorDistanceFor(cell: rightCell, point: point),
            colorDistanceFor(cell: forwardCell, point: point),
            colorDistanceFor(cell: backCell, point: point),
            colorDistanceFor(cell: topCell, point: point),
            colorDistanceFor(cell: bottomCell, point: point)
        ]
        
        let maxDist = cells.map({ $0.distance }).max()!
        
        return cells.reduce(.zero) {
            $0 + $1.color * (1.0 - $1.distance/maxDist)
        }
    }
    
    private func colorDistanceFor(cell: float3, point: float3) -> ColorDistance
    {
        let index = indexForCell(x: cell.x, y: cell.y, z: cell.z)
        
        let color = ambients[Int(index)]
        
        let pos = positionForCell(at: index)
        let dist = distance(point, pos)
        
        return ColorDistance(color: color, distance: dist)
    }
    
    private func indexForCell(x: Float, y: Float, z: Float) -> Float
    {
        let cellX = min(max(x, 0), lightVolSizeX)
        let cellY = min(max(y, 0), lightVolSizeY)
        let cellZ = min(max(z, 0), lightVolSizeZ)
        
        return cellX + cellY * lightVolSizeX + cellZ * lightVolSizeX * lightVolSizeY
    }
    
    private func cellForPoint(_ point: float3) -> float3
    {
        let cellX = floor(point.x / 64.0) - ceil(mins.x / 64.0) + 1.0
        let cellY = floor(point.y / 64.0) - ceil(mins.y / 64.0) + 1.0
        let cellZ = floor(point.z / 128.0) - ceil(mins.z / 128.0) + 1.0
        
        return float3(cellX, cellY, cellZ)
    }
    
    private func cellForIndex(_ index: Float) -> float3
    {
        let cellZ = index / (lightVolSizeX * lightVolSizeY) - 1
        
        let remaining = index.truncatingRemainder(dividingBy: (lightVolSizeX * lightVolSizeY))
        
        let cellY = remaining / lightVolSizeX
        let cellX = remaining.truncatingRemainder(dividingBy: lightVolSizeX)
        
        return float3(cellX, cellY, cellZ)
    }
    
    private func positionForCell(at index: Float) -> float3
    {
        let cell = cellForIndex(index)
        
        let x = cell.x * 64 + 32
        let y = cell.y * 64 + 32
        let z = cell.z * 128 + 64
        
        return float3(x, y, z) + mins
    }
}

