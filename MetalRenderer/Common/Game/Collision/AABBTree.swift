//
//  AABBTree.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 24.11.2023.
//

import Foundation
import simd

final class AABBTree
{
    var brushes: [Brush] = []
    var root: AABBNode?
    
    func loadFromAsset(_ asset: WorldCollisionAsset)
    {
        for brush in asset.brushes
        {
            if !(brush.contentFlags.contains(.SOLID) || brush.contentFlags.contains(.PLAYERCLIP)) {
                continue
            }
            
            let sides = asset.brushSides[brush.brushside ..< brush.brushside + brush.numBrushsides]
            let planes = sides.map { asset.planes[$0.plane] }
            
            let brush = Brush(planes: planes)
            brushes.append(brush)
        }
        
        root = build(objects: brushes)
    }
}

extension AABBTree
{
    func intersection(start: float3, end: float3) -> Intersection.Result?
    {
        guard let root = self.root else { return nil }
        
        let line = Intersection.Line(start: start, end: end)
        return intersect(line: line, node: root)
    }
    
    func traceBox(start: float3, end: float3, mins: float3, maxs: float3) -> HitResult?
    {
        return nil
    }
}

extension AABBTree
{
    // Функция для проверки пересечения луча с деревом
    private func intersect(line: Intersection.Line, node: AABBNode) -> Intersection.Result?
    {
        // Проверяем пересечение луча с текущим узлом
//        if let nodeResult = Intersection.hit(line: line, mins: node.boundingBox.min, maxs: node.boundingBox.max)
//        if lineIntersectionAABB(start: line.start, end: line.end, mins: node.boundingBox.min, maxs: node.boundingBox.max)
        if intersectSegmentWithAABB(start: line.start, end: line.end, box: node.boundingBox)
        {
            let transform = Transform()
            transform.position = node.boundingBox.center
            transform.scale = node.boundingBox.size

            Debug.shared.addCube(transform: transform, color: float4(1, 0, 0, 0.5))
            
            // Если луч пересекает текущий узел, проверяем его дочерние узлы
            if let leftChild = node.leftChild
            {
                if let leftResult = intersect(line: line, node: leftChild)
                {
                    return leftResult
                }
            }
            else if let rightChild = node.rightChild
            {
                if let rightResult = intersect(line: line, node: rightChild)
                {
                    return rightResult
                }
            }
            else
            {
                // Узел листовой
                
                
                
                if let brush = node.brush
                {
                    return Intersection.hit(line: line, mins: brush.minBounds, maxs: node.boundingBox.max)
                }
            }
        }
        
        return nil
    }
    
    private func intersectSegmentWithAABB(start: float3, end: float3, box: BoundingBox) -> Bool
    {
        let minCorner = min(box.min, box.max)
        let maxCorner = max(box.min, box.max)
        
        let startInside = (minCorner.x <= start.x && start.x <= maxCorner.x) &&
        (minCorner.y <= start.y && start.y <= maxCorner.y) &&
        (minCorner.z <= start.z && start.z <= maxCorner.z)
        
        let endInside = (minCorner.x <= end.x && end.x <= maxCorner.x) &&
        (minCorner.y <= end.y && end.y <= maxCorner.y) &&
        (minCorner.z <= end.z && end.z <= maxCorner.z)
        
        if startInside || endInside {
            // Один из концов отрезка находится внутри AABB
            return true
        }
        
        // Проверяем пересечение линии AABB с помощью проверки пересечения луча с AABB
        let ray = Ray(origin: start, direction: normalize(end - start))
        return intersect(ray: ray, box: box)
    }
    
    private func intersect(ray: Ray, box: BoundingBox) -> Bool
    {
        let t1 = (box.min - ray.origin) / ray.direction
        let t2 = (box.max - ray.origin) / ray.direction
        
        let tmin = max(max(min(t1.x, t2.x), min(t1.y, t2.y)), min(t1.z, t2.z))
        let tmax = min(min(max(t1.x, t2.x), max(t1.y, t2.y)), max(t1.z, t2.z))
        
        return tmax >= tmin && tmax >= 0
    }
}

extension AABBTree
{
    // Функция для построения AABB-дерева
    private func build(objects: [Brush]) -> AABBNode?
    {
        guard !objects.isEmpty else {
            return nil
        }
        
        // Вычисляем общий AABB для всех объектов
        let overallBox = computeBoundingBox(objects: objects)
        
        // Создаем корневой узел
        let rootNode = AABBNode(boundingBox: overallBox)
        
        // Рекурсивно строим дерево
        splitNode(node: rootNode, objects: objects)
        
        return rootNode
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

    // Вспомогательная функция для разделения узла дерева
    private func splitNode(node: AABBNode, objects: [Brush])
    {
        guard objects.count > 1 else {
            node.brush = objects.first
            return
        }
        
        // Выбираем ось, вдоль которой будем делить узел
        let axis = findSplitAxis(for: node.boundingBox)
        
        // Сортируем объекты по этой оси
        let sortedObjects = objects.sorted { (a, b) -> Bool in
            return a.minBounds[axis] < b.maxBounds[axis]
        }
        
        // Делим объекты на две части
        let mid = sortedObjects.count / 2
        let leftObjects = Array(sortedObjects.prefix(mid))
        let rightObjects = Array(sortedObjects.suffix(sortedObjects.count - mid))
        
        // Создаем дочерние узлы и рекурсивно строим дерево
        if !leftObjects.isEmpty
        {
            let leftChild = AABBNode(boundingBox: computeBoundingBox(objects: leftObjects))
            node.leftChild = leftChild
            
            splitNode(node: leftChild, objects: leftObjects)
        }
        
        if !rightObjects.isEmpty
        {
            let rightChild = AABBNode(boundingBox: computeBoundingBox(objects: rightObjects))
            node.rightChild = rightChild
            
            splitNode(node: rightChild, objects: rightObjects)
        }
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

struct BoundingBox
{
    var min: float3
    var max: float3
    
    var center: float3
    var size: float3
    
    // Minkowski sum
    func minkowski(with other: BoundingBox) -> BoundingBox
    {
        return BoundingBox(
            min: min - other.size * 0.5,
            max: max + other.size * 0.5
        )
    }
    
    init(min: float3, max: float3)
    {
        self.min = min
        self.max = max
        
        self.center = (min + max) * 0.5
        self.size = max - min
    }
}

// Узел AABB-дерева
class AABBNode
{
    var boundingBox: BoundingBox
    var leftChild: AABBNode?
    var rightChild: AABBNode?
    
    var brush: Brush?
    
    init(boundingBox: BoundingBox)
    {
        self.boundingBox = boundingBox
    }
}
