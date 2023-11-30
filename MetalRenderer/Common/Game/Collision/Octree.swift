//
//  Octree.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 29.01.2022.
//

import Foundation
import simd
//import MetalKit

struct Octant: CustomStringConvertible
{
    var boxMin: vector_float3
    var boxMax: vector_float3
    
    init(boxMin: vector_float3, boxMax: vector_float3)
    {
        self.boxMin = boxMin
        self.boxMax = boxMax
    }
    
    var boxSize: vector_float3 {
        return boxMax - boxMin
    }
    
    var halfBoxSize: vector_float3 {
        return boxSize * 0.5
    }
    
    var frontLeftTop: Octant {
        let boxMin = self.boxMin + vector_float3(0, halfBoxSize.y, halfBoxSize.z)
        let boxMax = self.boxMax - vector_float3(halfBoxSize.x, 0, 0)
        return Octant(boxMin: boxMin, boxMax: boxMax)
    }
    
    var frontLeftBottom: Octant {
        let boxMin = self.boxMin + vector_float3(0, 0, halfBoxSize.z)
        let boxMax = self.boxMax - vector_float3(halfBoxSize.x, halfBoxSize.y, 0)
        return Octant(boxMin: boxMin, boxMax: boxMax)
    }
    
    var frontRightTop: Octant {
        let boxMin = self.boxMin + vector_float3(halfBoxSize.x, halfBoxSize.y, halfBoxSize.z)
        let boxMax = self.boxMax - vector_float3(0, 0, 0)
        return Octant(boxMin: boxMin, boxMax: boxMax)
    }
    
    var frontRightBottom: Octant {
        let boxMin = self.boxMin + vector_float3(halfBoxSize.x, 0, halfBoxSize.z)
        let boxMax = self.boxMax - vector_float3(0, halfBoxSize.y, 0)
        return Octant(boxMin: boxMin, boxMax: boxMax)
    }
    
    var backLeftTop: Octant {
        let boxMin = self.boxMin + vector_float3(0, halfBoxSize.y, 0)
        let boxMax = self.boxMax - vector_float3(halfBoxSize.x, 0, halfBoxSize.z)
        return Octant(boxMin: boxMin, boxMax: boxMax)
    }
    
    var backLeftBottom: Octant {
        let boxMin = self.boxMin + vector_float3(0, 0, 0)
        let boxMax = self.boxMax - vector_float3(halfBoxSize.x, halfBoxSize.y, halfBoxSize.z)
        return Octant(boxMin: boxMin, boxMax: boxMax)
    }
    
    var backRightTop: Octant {
        let boxMin = self.boxMin + vector_float3(halfBoxSize.x, halfBoxSize.y, 0)
        let boxMax = self.boxMax - vector_float3(0, 0, halfBoxSize.z)
        return Octant(boxMin: boxMin, boxMax: boxMax)
    }
    
    var backRightBottom: Octant {
        let boxMin = self.boxMin + vector_float3(halfBoxSize.x, 0, 0)
        let boxMax = self.boxMax - vector_float3(0, halfBoxSize.y, halfBoxSize.z)
        return Octant(boxMin: boxMin, boxMax: boxMax)
    }
    
    func contains(_ point: vector_float3) -> Bool {
        return (boxMin.x <= point.x && point.x <= boxMax.x) && (boxMin.y <= point.y && point.y <= boxMax.y) && (boxMin.z <= point.z && point.z <= boxMax.z)
    }
    
    func contains(_ box: Octant) -> Bool {
        return
            self.boxMin.x <= box.boxMin.x &&
                self.boxMin.y <= box.boxMin.y &&
                self.boxMin.z <= box.boxMin.z &&
                self.boxMax.x >= box.boxMax.x &&
                self.boxMax.y >= box.boxMax.y &&
                self.boxMax.z >= box.boxMax.z
    }
    
    func isContained(in box: Octant) -> Bool {
        return
            self.boxMin.x >= box.boxMin.x &&
                self.boxMin.y >= box.boxMin.y &&
                self.boxMin.z >= box.boxMin.z &&
                self.boxMax.x <= box.boxMax.x &&
                self.boxMax.y <= box.boxMax.y &&
                self.boxMax.z <= box.boxMax.z
    }
    
    /* This intersect function does not handle all possibilities such as two beams
     of different diameter crossing each other half way. But it does cover all cases
     needed for an octree as the bounding box has to contain the given intersect box */
    func intersects(_ box: Octant) -> Bool {
        let corners = [
            vector_float3(boxMin.x, boxMax.y, boxMax.z), //frontLeftTop
            vector_float3(boxMin.x, boxMin.y, boxMax.z), //frontLeftBottom
            vector_float3(boxMax.x, boxMax.y, boxMax.z), //frontRightTop
            vector_float3(boxMax.x, boxMin.y, boxMax.z), //frontRightBottom
            vector_float3(boxMin.x, boxMax.y, boxMin.z), //backLeftTop
            vector_float3(boxMin.x, boxMin.y, boxMin.z), //backLeftBottom
            vector_float3(boxMax.x, boxMax.y, boxMin.z), //backRightTop
            vector_float3(boxMax.x, boxMin.y, boxMin.z)  //backRightBottom
        ]
        for corner in corners {
            if box.contains(corner) {
                return true
            }
        }
        return false
    }
    
    var description: String {
        return "Box from:\(boxMin) to:\(boxMax)"
    }
}

class OctreeNode<T: Equatable>: CustomStringConvertible
{
    let box: Octant
    var point: vector_float3!
    var elements: [T]!
    var type: NodeType = .leaf
    
//    var aabb: AABB?
    
    enum NodeType {
        case leaf
        case `internal`(children: Children)
    }
    
    public var description: String {
        switch type {
        case .leaf:
            return "leaf node with \(box) elements: \(elements)"
        case .internal:
            return "internal node with \(box)"
        }
    }
    
    var recursiveDescription: String {
        return recursiveDescription(withTabCount: 0)
    }
    
    private func recursiveDescription(withTabCount count: Int) -> String {
        let indent = String(repeating: "\t", count: count)
        var result = "\(indent)" + description + "\n"
        switch type {
        case .internal(let children):
            for child in children {
                result += child.recursiveDescription(withTabCount: count + 1)
            }
        default:
            break
        }
        return result
    }
    
//    func render(with encoder: MTLRenderCommandEncoder?)
//    {
//        aabb?.render(with: encoder)
//
//        switch type
//        {
//            case .internal(let children):
//                for child in children
//                {
//                    child.render(with: encoder)
//                }
//
//            default:
//                break
//        }
//    }
    
    struct Children: Sequence
    {
        let frontLeftTop: OctreeNode
        let frontLeftBottom: OctreeNode
        let frontRightTop: OctreeNode
        let frontRightBottom: OctreeNode
        let backLeftTop: OctreeNode
        let backLeftBottom: OctreeNode
        let backRightTop: OctreeNode
        let backRightBottom: OctreeNode
        
        init(parentNode: OctreeNode)
        {
            frontLeftTop = OctreeNode(box: parentNode.box.frontLeftTop)
            frontLeftBottom = OctreeNode(box: parentNode.box.frontLeftBottom)
            frontRightTop = OctreeNode(box: parentNode.box.frontRightTop)
            frontRightBottom = OctreeNode(box: parentNode.box.frontRightBottom)
            backLeftTop = OctreeNode(box: parentNode.box.backLeftTop)
            backLeftBottom = OctreeNode(box: parentNode.box.backLeftBottom)
            backRightTop = OctreeNode(box: parentNode.box.backRightTop)
            backRightBottom = OctreeNode(box: parentNode.box.backRightBottom)
        }
        
        struct ChildrenIterator: IteratorProtocol
        {
            var index = 0
            let children: Children
            
            init(children: Children) {
                self.children = children
            }
            
            mutating func next() -> OctreeNode?
            {
                defer { index += 1 }
                
                switch index
                {
                    case 0: return children.frontLeftTop
                    case 1: return children.frontLeftBottom
                    case 2: return children.frontRightTop
                    case 3: return children.frontRightBottom
                    case 4: return children.backLeftTop
                    case 5: return children.backLeftBottom
                    case 6: return children.backRightTop
                    case 7: return children.backRightBottom
                        
                    default: return nil
                }
            }
        }
        
        func makeIterator() -> ChildrenIterator {
            return ChildrenIterator(children: self)
        }
    }
    
    init(box: Octant)
    {
        self.box = box
//        self.aabb = AABB(min: box.boxMin, max: box.boxMax)
    }
    
    @discardableResult
    func add(_ element: T, at point: vector_float3) -> OctreeNode? {
        return tryAdd(element, at: point)
    }
    
    private func tryAdd(_ element: T, at point: vector_float3) -> OctreeNode?
    {
        if !box.contains(point) { return nil }
        
        switch type
        {
            case .internal(let children):
                // pass the point to one of the children
                for child in children
                {
                    if let child = child.tryAdd(element, at: point) {
                        return child
                    }
                }
                
                fatalError("box.contains evaluted to true, but none of the children added the point")
            case .leaf:
                if self.point != nil
                {
                    // leaf already has an asigned point
                    if self.point == point {
                        self.elements.append(element)
                        return self
                    } else {
                        return subdivide(adding: element, at: point)
                    }
                }
                else
                {
                    self.elements = [element]
                    self.point = point
                    return self
                }
        }
    }
    
    func add(_ elements: [T], at point: vector_float3)
    {
        for element in elements {
            self.add(element, at: point)
        }
    }
    
    @discardableResult
    func remove(_ element: T) -> Bool
    {
        switch type
        {
            case .leaf:
                if let elements = self.elements {
                    // leaf contains one ore more elements
                    if let index = elements.index(of: element) {
                        // leaf contains the element we want to remove
                        self.elements.remove(at: index)
                        // if elements is now empty remove it
                        if self.elements.isEmpty {
                            self.elements = nil
                        }
                        return true
                    }
                }
                return false
                
            case .internal(let children):
                for child in children  {
                    if child.remove(element) {
                        return true
                    }
                }
                return false
        }
    }
    
    func elements(at point: vector_float3) -> [T]?
    {
        switch type
        {
            case .leaf:
                if self.point == point
                {
                    return self.elements
                }
                
            case .internal(let children):
                for child in children {
                    if child.box.contains(point) {
                        return child.elements(at: point)
                    }
                }
        }
        
        // tree does not contain given point
        return nil
    }
    
    func elements(in box: Octant) -> [T]?
    {
        var values: [T] = []
        
        switch type
        {
            case .leaf:
                // check if leaf has an assigned point
                if let point = self.point {
                    // check if point is inside given box
                    if box.contains(point) {
                        values += elements ?? []
                    }
                }
                
            case .internal(let children):
                for child in children {
                    if child.box.isContained(in: box) {
                        // child is contained in box
                        // add all children of child
                        values += child.elements(in: child.box) ?? []
                    } else if child.box.contains(box) || child.box.intersects(box) {
                        // child contains at least part of box
                        values += child.elements(in: box) ?? []
                    }
                    // child does not contain any part of given box
                }
        }
        
        if values.isEmpty { return nil }
        
        return values
    }
    
    private func subdivide(adding element: T, at point: vector_float3) -> OctreeNode?
    {
        precondition(self.elements != nil, "Subdividing while leaf does not contain a element")
        precondition(self.point != nil, "Subdividing while leaf does not contain a point")
        
        switch type
        {
            case .leaf:
                type = .internal(children: Children(parentNode: self))
                // add element previously contained in leaf to children
                self.add(self.elements, at: self.point)
                self.elements = nil
                self.point = nil
                // add new element to children
                return self.add(element, at: point)
                
            case .internal:
                preconditionFailure("Calling subdivide on an internal node")
        }
    }
}

class Octree<T: Equatable>: CustomStringConvertible
{
    var root: OctreeNode<T>
    
    var description: String {
        return "Octree\n" + root.recursiveDescription
    }
    
    init(boundingBox: Octant, minimumCellSize: Double) {
        root = OctreeNode<T>(box: boundingBox)
    }
    
    @discardableResult
    func add(_ element: T, at point: vector_float3) -> OctreeNode<T>? {
        return root.add(element, at: point)
    }
    
    @discardableResult
    func remove(_ element: T, using node: OctreeNode<T>) -> Bool {
        return node.remove(element)
    }
    
    @discardableResult
    func remove(_ element: T) -> Bool {
        return root.remove(element)
    }
    
    func elements(at point: vector_float3) -> [T]? {
        return root.elements(at: point)
    }
    
    func elements(in box: Octant) -> [T]? {
        precondition(root.box.contains(box), "box is outside of octree bounds")
        return root.elements(in: box)
    }
    
//    func render(with encoder: MTLRenderCommandEncoder?)
//    {
//        root.render(with: encoder)
//    }
}
