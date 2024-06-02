//
//  WorldMesh.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 21.05.2024.
//

import Foundation
import Metal
import simd

protocol EditableObject: Entity, AnyObject
{
    var selectedFacePoint: float3? { get }
    var selectedFaceAxis: float3? { get }
    
    var selectedEdgePoint: float3? { get }
    var selectedEdgeAxis: float3? { get }
    
    var worldPosition: float3 { get }
    
    var isRoom: Bool { get set }
    var texture: String { get set }
    
    init(origin: float3, size: float3)
    
    func selectFace(by ray: Ray)
    func selectEdge(by ray: Ray)
    
    func setWorld(position: float3)
    func setSelectedFace(position: float3)
    func setSelectedEdge(position: float3)
}
