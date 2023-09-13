//
//  TextureManager.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 04.02.2022.
//

import MetalKit
import Quake3BSP

class TextureManager
{
    static let shared: TextureManager = TextureManager(with: Engine.device)
    
    private (set) var devTexture: MTLTexture!
    
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
        
        devTexture = getTexture(for: "Assets/dev_256.jpeg")!
    }
    
    func getTexture(for path: String, origin: MTKTextureLoader.Origin = .topLeft) -> MTLTexture?
    {
        if URL(string: path)!.pathExtension.isEmpty
        {
            if let url = ResourceManager.getURL(for: path + ".jpg")
            {
                return getTexture(url: url, origin: origin)
            }
            else if let url = ResourceManager.getURL(for: path + ".jpeg")
            {
                return getTexture(url: url, origin: origin)
            }
            else if let url = ResourceManager.getURL(for: path + ".tga")
            {
                return getTexture(url: url, origin: origin)
            }
            else
            {
                return nil
            }
        }
        
        guard let url = ResourceManager.getURL(for: path) else {
            return nil
        }
        
        return getTexture(url: url, origin: origin)
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
        catch
        {
            print("Can't create texture \(fileName)")
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
    
    func createTexture(_ name: String, bytes: [UInt8], width: Int, height: Int ) -> MTLTexture
    {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm_srgb,
                                                                  width: width,
                                                                  height: height,
                                                                  mipmapped: true)
        
        let texture = Engine.device.makeTexture(descriptor: descriptor)
        
        texture?.replace(region: MTLRegionMake2D(0, 0, width, height),
                         mipmapLevel: 0,
                         withBytes: bytes,
                         bytesPerRow: width * 4)
        
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
    
    func pngDataFrom(bytes: [UInt8], width: Int, height: Int, componentsCount: Int) -> Data?
    {
        guard let cgImage = CGImage.makeFrom(
            bytes: bytes,
            width: width,
            height: height
        ) else { return nil }
        
        let image = NSImage(cgImage: cgImage, size: .zero)
        let imageRep = NSBitmapImageRep(data: image.tiffRepresentation!)
        
        return imageRep?.representation(using: .png, properties: [:])
    }
}

private extension CGImage
{
    class func makeFrom(bytes: [UInt8], width: Int, height: Int, numComponents: Int = 4) -> CGImage?
    {
        let numBytes = height * width * numComponents
        
        let colorspace = CGColorSpaceCreateDeviceRGB()
        
        guard let rgbData = CFDataCreate(nil, bytes, numBytes) else { return nil }
        guard let provider = CGDataProvider(data: rgbData) else { return nil }
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        
        return CGImage(width: width,
                       height: height,
                       bitsPerComponent: 8,
                       bitsPerPixel: 8 * numComponents,
                       bytesPerRow: width * numComponents,
                       space: colorspace,
                       bitmapInfo: bitmapInfo,
                       provider: provider,
                       decode: nil,
                       shouldInterpolate: true,
                       intent: CGColorRenderingIntent.defaultIntent)
    }
}
