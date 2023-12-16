//
//  KdTree.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 30.11.2023.
//

import Foundation
import simd

final class KdTree
{
    var brushes: [Brush] = []
    var root: KdNode?
    
    func loadFromAsset(_ asset: WorldCollisionAsset)
    {
        for (index, brush) in asset.brushes.enumerated()
        {
            if !(brush.contentFlags.contains(.SOLID) || brush.contentFlags.contains(.PLAYERCLIP)) {
                continue
            }
            
            let name = brush.name ?? "brush_\(index)"
            
            let sides = asset.brushSides[brush.brushside ..< brush.brushside + brush.numBrushsides]
            let planes = sides.map { asset.planes[$0.plane] }
            
            let brush = Brush(planes: planes)
            brush.name = name
            
            brushes.append(brush)
        }
        
        root = build(objects: brushes)
    }
}

extension KdTree
{
    // Функция для построения AABB-дерева
    private func build(objects: [Brush]) -> KdNode?
    {
        guard !objects.isEmpty else {
            return nil
        }
        
        // Вычисляем общий AABB для всех объектов
        let overallBox = computeBoundingBox(objects: objects)
        
        // Создаем корневой узел
        let rootNode = KdNode(boundingBox: overallBox)
        
        // Рекурсивно строим дерево
        splitNode(node: rootNode, objects: objects, depth: 0)
        
        return rootNode
    }

    // Вспомогательная функция для разделения узла дерева
    private func splitNode(node: KdNode, objects: [Brush], depth: Int)
    {
        guard objects.count > 1 else {
            node.isLeaf = true
            node.items = objects
            return
        }
        
        // Выбираем ось, вдоль которой будем делить узел
//        let axis = findSplitAxis(for: node.boundingBox)
//        let distance = node.boundingBox.center[axis]
        
        let axis = depth % 3
        
        let center = node.boundingBox.center[axis]
        let values = objects
            .flatMap({ [$0.minBounds[axis], $0.maxBounds[axis]] })
            .sorted(by: { abs($0 - center) < abs($1 - center) })
        
        let distance = values.first ?? center
        
        node.plane = KdNode.Plane()
        node.plane?.axis = axis
        node.plane?.distance = distance
        
//        let plane = KdPlane(axis: axis, distance: distance)
        
        let leftObjects = objects.filter {
            $0.minBounds[axis] < distance
        }
        
        let rightObjects = objects.filter {
            $0.maxBounds[axis] > distance
        }
        
        // Создаем дочерние узлы и рекурсивно строим дерево
        if !leftObjects.isEmpty
        {
            var boundingBox = node.boundingBox
            boundingBox.max[axis] = distance
            
            let leftChild = KdNode(boundingBox: boundingBox)
            node.left = leftChild
            
            splitNode(node: leftChild, objects: leftObjects, depth: depth + 1)
        }
        
        if !rightObjects.isEmpty
        {
            var boundingBox = node.boundingBox
            boundingBox.min[axis] = distance
            
            let rightChild = KdNode(boundingBox: boundingBox)
            node.right = rightChild
            
            splitNode(node: rightChild, objects: rightObjects, depth: depth + 1)
        }
    }

    private func findSplitAxis(for aabb: BoundingBox) -> Int
    {
        // Выбираем ось разделения как ось с максимальной длиной
        var maxAxis = 0
        var maxLength = aabb.max[0] - aabb.min[0]

        for axis in 1...2
        {
            let length = aabb.max[axis] - aabb.min[axis]
                
            if length > maxLength
            {
                maxAxis = axis
                maxLength = length
            }
        }

        return maxAxis
    }
    
    // Вспомогательная функция для вычисления общего AABB для набора объектов
    private func computeBoundingBox(objects: [Brush]) -> BoundingBox
    {
        var minValues = SIMD3<Float>(repeating: Float.greatestFiniteMagnitude)
        var maxValues = SIMD3<Float>(repeating: -Float.greatestFiniteMagnitude)
        
        for object in objects
        {
            minValues.x = min(minValues.x, object.minBounds.x)
            minValues.y = min(minValues.y, object.minBounds.y)
            minValues.z = min(minValues.z, object.minBounds.z)
            
            maxValues.x = max(maxValues.x, object.maxBounds.x)
            maxValues.y = max(maxValues.y, object.maxBounds.y)
            maxValues.z = max(maxValues.z, object.maxBounds.z)
        }
        
        return BoundingBox(min: minValues, max: maxValues)
    }
}

class KdNode
{
    var boundingBox: BoundingBox
    
    var plane: Plane?
    var left: KdNode?
    var right: KdNode?
    
    var isLeaf = false
    var items: [Brush] = []
    
    init(boundingBox: BoundingBox)
    {
        self.boundingBox = boundingBox
    }
    
    class Plane
    {
        var axis: Int = -1
        var distance: Float = 0
    }
}
