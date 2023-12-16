//
//  BSP.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 08.12.2023.
//

import Foundation
import simd

final class BSPTree
{
    var root: BSPNode?
    var nodes: [BSPNode] = []
    
    var brushes: [Brush] = []
    
    func loadFromAsset(_ asset: WorldCollisionAsset)
    {
        for (index, brush) in asset.brushes.enumerated()
        {
//            if !(brush.contentFlags.contains(.SOLID) || brush.contentFlags.contains(.PLAYERCLIP)) {
//                continue
//            }
            
            let name = brush.name ?? "brush_\(index)"
            
            let sides = asset.brushSides[brush.brushside ..< brush.brushside + brush.numBrushsides]
            let planes = sides.map { asset.planes[$0.plane] }
            
            let brush = Brush(planes: planes)
            brush.name = name
            
            brushes.append(brush)
        }
        
        root = buildTree(for: asset.nodes.first!, with: asset)
    }
    
    private func buildTree(for assetNode: WorldCollisionAsset.Node, with asset: WorldCollisionAsset) -> BSPNode
    {
        let node = BSPNode()

        node.plane = BSPNode.Plane()
        node.plane?.normal = asset.planes[assetNode.plane].normal
        node.plane?.distance = asset.planes[assetNode.plane].distance

        let frontIndex = assetNode.child[0]
        let backIndex = assetNode.child[1]

        if frontIndex > 0
        {
            let child = asset.nodes[frontIndex]
            node.front = buildTree(for: child, with: asset)
        }
        else
        {
            let leafAsset = asset.leafs[-(frontIndex + 1)]

            node.front = BSPNode()
            node.front?.items = leafAsset.brushes.map { brushes[$0] }
            node.front?.isLeaf = true
        }

        if backIndex > 0
        {
            let child = asset.nodes[backIndex]
            node.back = buildTree(for: child, with: asset)
        }
        else
        {
            let leafAsset = asset.leafs[-(backIndex + 1)]

            node.back = BSPNode()
            node.back?.items = leafAsset.brushes.map { brushes[$0] }
            node.back?.isLeaf = true
        }
        
        return node
    }
}

final class BSPNode
{
    class Plane
    {
        var normal: SIMD3<Float> = .zero
        var distance: Float = 0
    }
    
    var plane: Plane?
    var front: BSPNode?
    var back: BSPNode?
    
    var isLeaf: Bool = false
    var items: [Brush] = []
}

