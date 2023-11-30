//
//  SceneKitWrapper.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 30.11.2023.
//

import Foundation
import SceneKit
import simd

// Used just for utility purposes like save brushes as .dae for viewing
final class SceneKitWrapper: NSObject
{
    let scene = SCNScene()
    
    func loadFromAsset(_ asset: WorldCollisionAsset, named: String)
    {
        for (index, brush) in asset.brushes.enumerated()
        {
            if !(brush.contentFlags.contains(.SOLID) || brush.contentFlags.contains(.PLAYERCLIP)) {
                continue
            }
            
            let sides = asset.brushSides[brush.brushside ..< brush.brushside + brush.numBrushsides]
            let planes = sides.map { asset.planes[$0.plane] }
            
            let brush = Brush(planes: planes)
            
            // Quake coordinate system to Metal (+Y = up) and scaling to 1u = 1m
            let matrix = matrix_float4x4([
                float4(0, 0, -0.0254, 0),
                float4(-0.0254, 0, 0, 0),
                float4(0, 0.0254, 0, 0),
                float4(0, 0, 0, 1)
            ])
            
            let pos = matrix * (brush.maxBounds + brush.minBounds) * 0.5
            
            let node = SCNNode()
            node.name = "brush_\(index)"
            node.position = SCNVector3(pos)

            let source = SCNGeometrySource(
                vertices: brush.triangles.map({ SCNVector3(matrix * $0 - pos) })
            )
            
            let element = SCNGeometryElement(
                indices: Array(Int32(0) ..< Int32(brush.triangles.count)),
                primitiveType: .triangles
            )
            
            node.geometry = SCNGeometry(sources: [source], elements: [element])
            
            let shape = SCNPhysicsShape(geometry: node.geometry!)
            
            node.physicsBody = SCNPhysicsBody(type: .static, shape: shape)
            
            scene.rootNode.addChildNode(node)
        }
        
        scene.rootNode.name = named
    }
    
    func saveScene()
    {
        if let url = UserDefaults.standard
            .url(forKey: "workingDir")?
            .appendingPathComponent(scene.rootNode.name!)
            .appendingPathExtension("dae")
        {
            scene.write(to: url, delegate: nil)
        }
    }
}

extension SceneKitWrapper
{
    func intersection(start: float3, end: float3) -> Intersection.Result?
    {
        let from = SCNVector3(x: CGFloat(start.x), y: CGFloat(start.y), z: CGFloat(start.z))
        let to = SCNVector3(x: CGFloat(end.x), y: CGFloat(end.y), z: CGFloat(end.z))
        
        let hits = scene.physicsWorld.rayTestWithSegment(
            from: from,
            to: to,
            options: [
                .backfaceCulling: true,
                .searchMode: SCNPhysicsWorld.TestSearchMode.closest
            ]
        )
        
        for hit in hits
        {
            let point = hit.simdWorldCoordinates
            let normal = hit.simdWorldNormal
            
            return Intersection.Result(point: point, normal: normal, index: -1)
        }
        
        return nil
    }
    
    func traceBox(start: float3, end: float3, mins: float3, maxs: float3) -> SCNPhysicsContact?
    {
        let size = maxs - mins
        
        let box = SCNBox(width: CGFloat(size.x), height: CGFloat(size.y), length: CGFloat(size.z), chamferRadius: 0)
        let shape = SCNPhysicsShape(geometry: box)
        
        var from = SCNMatrix4MakeTranslation(CGFloat(start.x), CGFloat(start.y), CGFloat(start.z))
        var to = SCNMatrix4MakeTranslation(CGFloat(end.x), CGFloat(end.y), CGFloat(end.z))
        
        from = SCNMatrix4Scale(from, CGFloat(size.x), CGFloat(size.y), CGFloat(size.z))
        to = SCNMatrix4Scale(to, CGFloat(size.x), CGFloat(size.y), CGFloat(size.z))
        
        let contacts = scene.physicsWorld.convexSweepTest(
            with: shape,
            from: from,
            to: to,
            options: [
                .backfaceCulling: true,
                .searchMode: SCNPhysicsWorld.TestSearchMode.closest
            ]
        )
        
        return contacts.first
    }
}
