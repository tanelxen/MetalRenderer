//
//  UserInterface.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 15.09.2023.
//

import Foundation
import Metal
import simd

final class UserInterface
{
    static let shared = UserInterface()
    
    private var texture: MTLTexture!
    
    private var width: Float = 1
    private var height: Float = 1
    
    init()
    {
        texture = TextureManager.shared.getTexture(for: "Assets/crosshairc.tga")
    }
    
    func update(width: Int, height: Int)
    {
        self.width = Float(width)
        self.height = Float(height)
    }
    
    func draw(with encoder: MTLRenderCommandEncoder)
    {
        drawCrosshair(with: encoder)
    }
    
    private func drawCrosshair(with encoder: MTLRenderCommandEncoder)
    {
        let size: Float = 30
        let halfSize = size * 0.5
        
        let centerX = width * 0.5
        let centerY = height * 0.5
        
        var vertices: [float4] = [
            // x, y, u, v
            float4(centerX - halfSize, centerY - halfSize, 0, 0),   // left     top
            float4(centerX - halfSize, centerY + halfSize, 0, 1),   // left     bottom
            float4(centerX + halfSize, centerY - halfSize, 1, 0),   // right    top
            float4(centerX + halfSize, centerY + halfSize, 1, 1)    // right    bottom
        ]
        
        var color = float4(1, 0, 1, 1)
        
        encoder.setVertexBytes(&vertices, length: MemoryLayout<float4>.stride * vertices.count, index: 0)
        encoder.setVertexBytes(&color, length: MemoryLayout<float4>.stride * vertices.count, index: 2)
        
        encoder.setFragmentTexture(texture, index: 0)
        
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertices.count)
    }
}
