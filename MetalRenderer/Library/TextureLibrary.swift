//
//  TextureLibrary.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

enum TextureTypes
{
    case none
    
    case skull
    case skysphere
}

enum TextureLibrary
{
    private static var textures: [TextureTypes : MTLTexture] = [:]
    
    static func initialize()
    {
        textures.updateValue(
            TextureLoader("skull", ext: "jpg", origin: .bottomLeft).loadFromBundle(),
            forKey: .skull
        )
        
        textures.updateValue(
            TextureLoader("clouds2", ext: "jpg", origin: .bottomLeft).loadFromBundle(),
            forKey: .skysphere
        )
    }
    
    static func set(_ texture: MTLTexture, for type: TextureTypes)
    {
        textures.updateValue(texture, forKey: .skull)
    }
    
    static subscript(_ type: TextureTypes) -> MTLTexture?
    {
        return textures[type]
    }
}

private class TextureLoader
{
    private var fileName: String
    private var fileExtension: String
    private var origin: MTKTextureLoader.Origin
    
    init(_ name: String, ext: String = "png", origin: MTKTextureLoader.Origin = .topLeft)
    {
        self.fileName = name
        self.fileExtension = ext
        self.origin = origin
    }
    
    func loadFromBundle() -> MTLTexture
    {
        var result: MTLTexture!
        
        if let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension)
        {
            let textureLoader = MTKTextureLoader(device: Engine.device)
            
            let options: [MTKTextureLoader.Option : MTKTextureLoader.Origin] = [MTKTextureLoader.Option.origin : origin]
            
            do
            {
                result = try textureLoader.newTexture(URL: url, options: options)
                result.label = fileName
            }
            catch let error as NSError
            {
                print("ERROR::CREATING::TEXTURE::__\(fileName)__::\(error)")
            }
        }
        else
        {
            print("ERROR::CREATING::TEXTURE::__\(fileName) does not exist")
        }
        
        return result
    }
}

