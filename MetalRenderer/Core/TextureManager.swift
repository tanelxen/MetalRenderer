//
//  TextureManager.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 04.02.2022.
//

import MetalKit

class TextureManager
{
    static let shared: TextureManager = TextureManager(with: Engine.device)
    
    private let _textureLoader: MTKTextureLoader
    private var _cache: [String: MTLTexture] = [:]
    
    private var _whiteTexture: MTLTexture?
    
    private let lightmapDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                              width: 128,
                                                                              height: 128,
                                                                              mipmapped: true)
    
    // Для генерации mip-уровней
    private let _commandQueue: MTLCommandQueue
    
    init(with device: MTLDevice)
    {
        _textureLoader = MTKTextureLoader(device: Engine.device)
        _commandQueue = Engine.device.makeCommandQueue()!
    }
    
    func getTexture(url: URL, origin: MTKTextureLoader.Origin = .topLeft) -> MTLTexture?
    {
        let fileName = url.lastPathComponent
        
        if let texture = _cache[fileName]
        {
            return texture
        }
        
        var texture: MTLTexture?
        
        let options: [MTKTextureLoader.Option : MTKTextureLoader.Origin] = [MTKTextureLoader.Option.origin : origin]
        
        do
        {
            texture = try _textureLoader.newTexture(URL: url, options: options)
            texture?.label = fileName
        }
        catch let error as NSError
        {
            print("ERROR::CREATING::TEXTURE::__\(fileName)__::\(error)")
        }
        
        _cache[fileName] = texture
        
        return texture
    }
    
    func loadCubeTexture(imageName: String) -> MTLTexture?
    {
        if let texture = MDLTexture(cubeWithImagesNamed: [imageName])
        {
            let options: [MTKTextureLoader.Option: Any] = [
                .origin: MTKTextureLoader.Origin.bottomLeft,
                .SRGB: false,
                .generateMipmaps: NSNumber(booleanLiteral: false)
            ]
            
            return try? _textureLoader.newTexture(texture: texture, options: options)
        }
        
        let texture = try? _textureLoader.newTexture(name: imageName, scaleFactor: 1.0, bundle: .main)
        
        return texture
    }
    
    func whiteTexture() -> MTLTexture
    {
        if let _whiteTexture = self._whiteTexture { return _whiteTexture }
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                  width: 1,
                                                                  height: 1,
                                                                  mipmapped: false)
        
        let whiteTexture = Engine.device.makeTexture(descriptor: descriptor)
        
        let bytes = [UInt8(255), UInt8(255), UInt8(255), UInt8(255)]
        
        whiteTexture?.replace(region: MTLRegionMake2D(0, 0, 1, 1),
                              mipmapLevel: 0,
                              withBytes: bytes,
                              bytesPerRow: MemoryLayout<UInt8>.size * bytes.count)
        
        self._whiteTexture = whiteTexture
        
        return whiteTexture!
    }
    
    func loadLightmap(_ lightmap: Q3Lightmap) -> MTLTexture
    {
        let texture = Engine.device.makeTexture(descriptor: lightmapDescriptor)
        
        texture?.replace(region: MTLRegionMake2D(0, 0, 128, 128),
                         mipmapLevel: 0,
                         withBytes: lightmap,
                         bytesPerRow: 128 * 4)
        
        generateMipmaps(texture!)
        
        return texture!
    }
    
    private func generateMipmaps(_ texture: MTLTexture)
    {
        let commandBuffer = _commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeBlitCommandEncoder()
        
        commandEncoder?.generateMipmaps(for: texture)
        
        commandEncoder?.endEncoding()
        commandBuffer?.commit()
    }
}
