//
//  Utils.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 21.01.2022.
//

import Foundation
import MetalKit

enum Utils
{
    static func timeProfile(_ label: String, closure: () -> Void)
    {
        let start = CFAbsoluteTimeGetCurrent()

        closure()

        let diff = (CFAbsoluteTimeGetCurrent() - start) * 1000
        print("\(label) \(diff) ms")
    }
    
    static func createTexture(data: [float4], width: Int, height: Int) -> MTLTexture?
    {
        let pointer: UnsafeMutablePointer<float4> = UnsafeMutablePointer(mutating: data)

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float, width: width, height: height, mipmapped: false)

        guard let texture: MTLTexture = Engine.device.makeTexture(descriptor: textureDescriptor) else { return nil }

        let region = MTLRegion.init(origin: MTLOrigin.init(x: 0, y: 0, z: 0), size: MTLSize.init(width: texture.width, height: texture.height, depth: 1))

        texture.replace(region: region, mipmapLevel: 0, withBytes: pointer, bytesPerRow: width * 4 * 2)

        return texture
    }
    
    static func makeNoiseTexture(width: Int, height: Int) -> MTLTexture?
    {
        var ssaoNoise: [float4] = []
        
        let num = width * height
        
        for _ in 0..<num
        {
            let x: Float = Float.random(in: 0...1)
            let y: Float = Float.random(in: 0...1)
            let z: Float = Float.random(in: 0...1)

            ssaoNoise.append(float4(x, y, z, 1.0))
        }
        
        return Utils.createTexture(data: ssaoNoise, width: width, height: height)
    }
}
