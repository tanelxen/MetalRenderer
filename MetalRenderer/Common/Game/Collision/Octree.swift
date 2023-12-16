//
//  Octree.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 29.01.2022.
//

import Foundation
import simd

final class Octree
{
    var root: OctreeNode?
    var nodes: [OctreeNode] = []
    
    var brushes: [Brush] = []
    
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
        
        root = buildTree(for: brushes)
    }
    
    private func buildTree(for items: [Brush]) -> OctreeNode?
    {
        guard !items.isEmpty else { return nil }

        let bounds = overallBoundingBox(for: items)
        let root = OctreeNode(boundingBox: bounds)
        
        nodes.append(root)
        
        split(node: root, items: items, depth: 0)
        
        var maxDepth = 0
        
        for node in nodes
        {
            if node.depth > maxDepth
            {
                maxDepth = node.depth
            }
        }
        
        print("octree.maxDepth", maxDepth)
        
        for node in nodes
        {
            node.children = [
                node.frontLeftTop,
                node.frontLeftBottom,
                node.frontRightTop,
                node.frontRightBottom,
                node.backLeftTop,
                node.backLeftBottom,
                node.backRightTop,
                node.backRightBottom
            ].compactMap({ $0 })
        }

        return root
    }
    
    private func split(node: OctreeNode, items: [Brush], depth: Int)
    {
        node.depth = depth
        
        guard items.count > 1 && node.boundingBox.hasValidSize else {
            node.isLeaf = true
            node.items = items
            return
        }
        
        let frontLeftTopBounds = node.boundingBox.frontLeftTop
        let frontLeftBottomBounds = node.boundingBox.frontLeftBottom
        let frontRightTopBounds = node.boundingBox.frontRightTop
        let frontRightBottomBounds = node.boundingBox.frontRightBottom
        
        let backLeftTopBounds = node.boundingBox.backLeftTop
        let backLeftBottomBounds = node.boundingBox.backLeftBottom
        let backRightTopBounds = node.boundingBox.backRightTop
        let backRightBottomBounds = node.boundingBox.backRightBottom
        
        let frontLeftTopItems = items.filter({ isIntersect($0.bounds, frontLeftTopBounds) })
        let frontLeftBottomItems = items.filter({ isIntersect($0.bounds, frontLeftBottomBounds) })
        let frontRightTopItems = items.filter({ isIntersect($0.bounds, frontRightTopBounds) })
        let frontRightBottomItems = items.filter({ isIntersect($0.bounds, frontRightBottomBounds) })
        
        let backLeftTopItems = items.filter({ isIntersect($0.bounds, backLeftTopBounds) })
        let backLeftBottomItems = items.filter({ isIntersect($0.bounds, backLeftBottomBounds) })
        let backRightTopItems = items.filter({ isIntersect($0.bounds, backRightTopBounds) })
        let backRightBottomItems = items.filter({ isIntersect($0.bounds, backRightBottomBounds) })
    
        
        if !frontLeftTopItems.isEmpty
        {
            let child = OctreeNode(boundingBox: frontLeftTopBounds)
            node.frontLeftTop = child
            
            nodes.append(child)
            
            split(node: child, items: frontLeftTopItems, depth: depth + 1)
        }
        
        if !frontLeftBottomItems.isEmpty
        {
            let child = OctreeNode(boundingBox: frontLeftBottomBounds)
            node.frontLeftBottom = child
            
            nodes.append(child)
            
            split(node: child, items: frontLeftBottomItems, depth: depth + 1)
        }
        
        if !frontRightTopItems.isEmpty
        {
            let child = OctreeNode(boundingBox: frontRightTopBounds)
            node.frontRightTop = child
            
            nodes.append(child)
            
            split(node: child, items: frontRightTopItems, depth: depth + 1)
        }
        
        if !frontRightBottomItems.isEmpty
        {
            let child = OctreeNode(boundingBox: frontRightBottomBounds)
            node.frontRightBottom = child
            
            nodes.append(child)
            
            split(node: child, items: frontRightBottomItems, depth: depth + 1)
        }
        
        if !backLeftTopItems.isEmpty
        {
            let child = OctreeNode(boundingBox: backLeftTopBounds)
            node.backLeftTop = child
            
            nodes.append(child)
            
            split(node: child, items: backLeftTopItems, depth: depth + 1)
        }
        
        if !backLeftBottomItems.isEmpty
        {
            let child = OctreeNode(boundingBox: backLeftBottomBounds)
            node.backLeftBottom = child
            
            nodes.append(child)
            
            split(node: child, items: backLeftBottomItems, depth: depth + 1)
        }
        
        if !backRightTopItems.isEmpty
        {
            let child = OctreeNode(boundingBox: backRightTopBounds)
            node.backRightTop = child
            
            nodes.append(child)
            
            split(node: child, items: backRightTopItems, depth: depth + 1)
        }
        
        if !backRightBottomItems.isEmpty
        {
            let child = OctreeNode(boundingBox: backRightBottomBounds)
            node.backRightBottom = child
            
            nodes.append(child)
            
            split(node: child, items: backRightBottomItems, depth: depth + 1)
        }
    }
    
    private func isIntersect(_ first: BoundingBox, _ second: BoundingBox) -> Bool
    {
        return first.min.x <= second.max.x &&
        first.max.x >= second.min.x &&
        first.min.y <= second.max.y &&
        first.max.y >= second.min.y &&
        first.min.z <= second.max.z &&
        first.max.z >= second.min.z
    }
    
    private func isFirstFullInsideSecond(_ first: BoundingBox, _ second: BoundingBox) -> Bool
    {
        return first.min.x > second.min.x &&
        first.max.x < second.max.x &&
        first.min.y > second.min.y &&
        first.max.y < second.max.y &&
        first.min.z > second.min.z &&
        first.max.z < second.max.z
    }
    
    private func overallBoundingBox(for objects: [Brush]) -> BoundingBox
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

extension Octree
{
    func intersection(start: float3, end: float3) -> Intersection.Result?
    {
        guard let root = self.root else { return nil }
        
        let line = Intersection.Line(start: start, end: end)
        return intersect(line: line, node: root)
    }
    
    private func intersect(line: Intersection.Line, node: OctreeNode) -> Intersection.Result?
    {
        if intersectSegmentWithAABB(start: line.start, end: line.end, box: node.boundingBox)
        {
            let transform = Transform()
            transform.position = node.boundingBox.center
            transform.scale = node.boundingBox.size

            Debug.shared.addCube(transform: transform, color: float4(1, 0, 0, 0.5))
            
            if node.isLeaf
            {
                var hitResult = HitResult()
                hitResult.fraction = 1.0
                hitResult.start = line.start
                hitResult.end = line.end
                
                // Узел листовой
                for item in node.items
                {
                    trace_brush(item, work: &hitResult)
                }
                
                if hitResult.fraction < 1
                {
                    let point = line.start + hitResult.fraction * (line.end - line.start)
                    return Intersection.Result(point: point, normal: hitResult.plane!.normal, index: 0)
                }
                
                return nil
            }
            
            let childs = [
                node.frontLeftTop,
                node.frontLeftBottom,
                node.frontRightTop,
                node.frontRightBottom,
                node.backLeftTop,
                node.backLeftBottom,
                node.backRightTop,
                node.backRightBottom
            ]
            
            let sorted = childs
                .compactMap({ $0 })
                .sorted(by: { length($0.boundingBox.center - line.start) < length($1.boundingBox.center - line.start)
            })
            
            for child in sorted
            {
                if let result = intersect(line: line, node: child)
                {
                    return result
                }
            }
        }
        
        return nil
    }
    
    private func trace_brush(_ brush: Brush, work: inout HitResult)
    {
        var start_frac: Float = -1.0
        var end_frac: Float = 1.0
        var closest_plane: WorldCollisionAsset.Plane?
        
        var getout = false
        var startout = false
        
        for plane in brush.planes
        {
            let signbits = plane.signbits
            let dist = plane.distance - dot(work.offsets[signbits], plane.normal)

            let start_distance = dot(work.start, plane.normal) - dist
            let end_distance = dot(work.end, plane.normal) - dist

            if start_distance > 0
            {
                startout = true
            }
            
            if end_distance > 0
            {
                getout = true // endpoint is not in solid
            }

            // make sure the trace isn't completely on one side of the brush
            // both are in front of the plane, its outside of this brush
            if (start_distance > 0 && (end_distance >= SURF_CLIP_EPSILON || end_distance >= start_distance)) { return }
            
            // both are behind this plane, it will get clipped by another one
            if (start_distance <= 0 && end_distance <= 0) { continue }
            

            if start_distance > end_distance
            {
                let frac = (start_distance - SURF_CLIP_EPSILON) / (start_distance - end_distance)
                
                if frac > start_frac
                {
                    start_frac = frac
                    closest_plane = plane
                }
            }
            else // line is leaving the brush
            {
                let frac = (start_distance + SURF_CLIP_EPSILON) / (start_distance - end_distance)
                
                end_frac = min(end_frac, frac)
            }
        }
        
        if !startout
        {
            // original point was inside brush
            work.startsolid = true
            
            if !getout
            {
                work.allsolid = true
                work.fraction = 0
            }
            
            return
        }
        
        if start_frac < end_frac && start_frac > -1 && start_frac < work.fraction
        {
            work.fraction = max(start_frac, 0)
            work.plane = closest_plane
        }
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
    
    private func overallBoundingBox(for boxes: [BoundingBox]) -> BoundingBox
    {
        var minValues = SIMD3<Float>(repeating: Float.greatestFiniteMagnitude)
        var maxValues = SIMD3<Float>(repeating: -Float.greatestFiniteMagnitude)
        
        for box in boxes
        {
            minValues.x = min(minValues.x, box.min.x)
            minValues.y = min(minValues.y, box.min.y)
            minValues.z = min(minValues.z, box.min.z)
            
            maxValues.x = max(maxValues.x, box.max.x)
            maxValues.y = max(maxValues.y, box.max.y)
            maxValues.z = max(maxValues.z, box.max.z)
        }
        
        return BoundingBox(min: minValues, max: maxValues)
    }
}

extension Octree
{
    func traceBox(result work: inout HitResult, start: float3, end: float3, mins: float3, maxs: float3)
    {
        work.fraction = 1
        
        // Make symmetrical
        for i in 0...2
        {
            let offset = (mins[i] + maxs[i]) * 0.5
            
            work.mins[i] = mins[i] - offset
            work.maxs[i] = maxs[i] - offset
            work.start[i] = start[i] + offset
            work.end[i] = end[i] + offset
        }
        
        work.offsets[0][0] = work.mins[0]
        work.offsets[0][1] = work.mins[1]
        work.offsets[0][2] = work.mins[2]
        
        work.offsets[1][0] = work.maxs[0]
        work.offsets[1][1] = work.mins[1]
        work.offsets[1][2] = work.mins[2]
        
        work.offsets[2][0] = work.mins[0]
        work.offsets[2][1] = work.maxs[1]
        work.offsets[2][2] = work.mins[2]
        
        work.offsets[3][0] = work.maxs[0]
        work.offsets[3][1] = work.maxs[1]
        work.offsets[3][2] = work.mins[2]
        
        work.offsets[4][0] = work.mins[0]
        work.offsets[4][1] = work.mins[1]
        work.offsets[4][2] = work.maxs[2]
        
        work.offsets[5][0] = work.maxs[0]
        work.offsets[5][1] = work.mins[1]
        work.offsets[5][2] = work.maxs[2]
        
        work.offsets[6][0] = work.mins[0]
        work.offsets[6][1] = work.maxs[1]
        work.offsets[6][2] = work.maxs[2]
        
        work.offsets[7][0] = work.maxs[0]
        work.offsets[7][1] = work.maxs[1]
        work.offsets[7][2] = work.maxs[2]
        
        work.tracedBox = BoundingBox(min: work.mins, max: work.maxs)
        
        if let root = self.root
        {
            trace_node(work: &work, node: root, start: start, end: end)
        }
        
//        print("checkedNodesCount", work.checkedNodesCount, "checkedBrushesCount", work.checkedBrushesCount)

        if work.fraction == 1.0
        {
            // nothing blocked the trace
            work.endpos = end
        }
        else
        {
            // collided with something
            work.endpos = start + work.fraction * (end - start)
        }
    }
    
    private func trace_node(work: inout HitResult, node: OctreeNode, start: float3, end: float3)
    {
        work.checkedNodesCount += 1
        
        let minkowski = node.boundingBox.minkowski(with: work.tracedBox)
        let check = lineIntersectionAABB(start: start, end: end, mins: minkowski.min, maxs: minkowski.max)
        
        guard check else { return }
        
        if node.isLeaf
        {
            // Узел листовой
            for item in node.items
            {
                work.checkedBrushesCount += 1
                trace_brush(item, work: &work)
            }
            
            return
        }
        
        let sorted = node.children.sorted(by: {
            length_squared($0.boundingBox.center - start) < length_squared($1.boundingBox.center - start)
        })
        
        for child in sorted
        {
            trace_node(work: &work, node: child, start: start, end: end)
            
            if work.fraction < 1 {
                break
            }
        }
    }
}

fileprivate let SURF_CLIP_EPSILON: Float = 0.125

final class OctreeNode
{
    var boundingBox: BoundingBox
    
    var frontLeftTop: OctreeNode?
    var frontLeftBottom: OctreeNode?
    var frontRightTop: OctreeNode?
    var frontRightBottom: OctreeNode?
    
    var backLeftTop: OctreeNode?
    var backLeftBottom: OctreeNode?
    var backRightTop: OctreeNode?
    var backRightBottom: OctreeNode?
    
    var children: [OctreeNode] = []

    var isLeaf = false
    var items: [Brush] = []
    
    var depth = 0

    init(boundingBox: BoundingBox)
    {
        self.boundingBox = boundingBox
    }
}

private extension BoundingBox
{
    private var halfSize: float3 {
        size * 0.5
    }
    
    var hasValidSize: Bool {
        size.x > 32 && size.y > 32 && size.z > 32
    }
    
    var frontLeftTop: BoundingBox {
        BoundingBox(min: center + SIMD3<Float>(0, 0, 0),
                    max: center + SIMD3<Float>(halfSize.x, halfSize.y, halfSize.z))
    }
    
    var frontLeftBottom: BoundingBox {
        BoundingBox(min: center + SIMD3<Float>(0, 0, -halfSize.z),
                    max: center + SIMD3<Float>(halfSize.x, halfSize.y, 0))
    }
    
    var frontRightTop: BoundingBox {
        BoundingBox(min: center + SIMD3<Float>(0, -halfSize.y, 0),
                    max: center + SIMD3<Float>(halfSize.x, 0, halfSize.z))
    }
    
    var frontRightBottom: BoundingBox {
        BoundingBox(min: center + SIMD3<Float>(0, -halfSize.y, -halfSize.z),
                    max: center + SIMD3<Float>(halfSize.x, 0, 0))
    }
    
    var backLeftTop: BoundingBox {
        BoundingBox(min: center + SIMD3<Float>(-halfSize.x, 0, 0),
                    max: center + SIMD3<Float>(0, halfSize.y, halfSize.z))
    }
    
    var backLeftBottom: BoundingBox {
        BoundingBox(min: center + SIMD3<Float>(-halfSize.x, 0, -halfSize.z),
                    max: center + SIMD3<Float>(0, halfSize.y, 0))
    }
    
    var backRightTop: BoundingBox {
        BoundingBox(min: center + SIMD3<Float>(-halfSize.x, -halfSize.y, 0),
                    max: center + SIMD3<Float>(0, 0, halfSize.z))
    }
    
    var backRightBottom: BoundingBox {
        BoundingBox(min: center + SIMD3<Float>(-halfSize.x, -halfSize.y, -halfSize.z),
                    max: center + SIMD3<Float>(0, 0, 0))
    }
}

private extension WorldCollisionAsset.Plane
{
    var signbits: Int {
        var bits = 0
        
        for i in 0...2
        {
            if normal[i] < 0 {
                bits |= 1 << i
            }
        }
        
        return bits
    }
}
