//
//  Mesh.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

protocol Mesh
{
    var transform: matrix_float4x4 { get set }
    var vertexBuffer: MTLBuffer! { get }
    
    var material: Material { get set }
    
    func doRender(with encoder: MTLRenderCommandEncoder?)
    
    func drawPrimitives(with encoder: MTLRenderCommandEncoder?)
}
