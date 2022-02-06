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
    
    init(with device: MTLDevice)
    {
        _textureLoader = MTKTextureLoader(device: Engine.device)
    }
    
//    func getTexture(named name: String, ext: String = "png", origin: MTKTextureLoader.Origin = .topLeft) -> MTLTexture?
//    {
//        if let texture = _cache[name]
//        {
//            return texture
//        }
//
//        var texture: MTLTexture?
//
//        if let url = Bundle.main.url(forResource: name, withExtension: ext)
//        {
//            let textureLoader = MTKTextureLoader(device: Engine.device)
//
//            let options: [MTKTextureLoader.Option : MTKTextureLoader.Origin] = [MTKTextureLoader.Option.origin : origin]
//
//            do
//            {
//                texture = try textureLoader.newTexture(URL: url, options: options)
//                texture?.label = name
//            }
//            catch let error as NSError
//            {
//                print("ERROR::CREATING::TEXTURE::__\(name)__::\(error)")
//            }
//        }
//        else
//        {
//            print("ERROR::CREATING::TEXTURE::__\(name) does not exist")
//        }
//
//        _cache[name] = texture
//
//        return texture
//    }
    
    func getTexture(url: URL, origin: MTKTextureLoader.Origin = .topLeft) -> MTLTexture?
    {
        let fileName = url.lastPathComponent
        
        if let texture = _cache[fileName]
        {
            return texture
        }
        
        var texture: MTLTexture?
        
        let textureLoader = MTKTextureLoader(device: Engine.device)
        
        let options: [MTKTextureLoader.Option : MTKTextureLoader.Origin] = [MTKTextureLoader.Option.origin : origin]
        
        do
        {
            texture = try textureLoader.newTexture(URL: url, options: options)
            texture?.label = fileName
        }
        catch let error as NSError
        {
            print("ERROR::CREATING::TEXTURE::__\(fileName)__::\(error)")
        }
        
        _cache[fileName] = texture
        
        return texture
    }
}
