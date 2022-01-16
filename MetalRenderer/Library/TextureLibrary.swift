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
    case partyPirateParot
    case cruiser
    case skull
}

enum TextureLibrary
{
    private static var textures: [TextureTypes : Texture] = [:]
    
    static func initialize()
    {
        textures.updateValue(Texture("PartyPirateParot"), forKey: .partyPirateParot)
        textures.updateValue(Texture("cruiser", ext: "bmp"), forKey: .cruiser)
        textures.updateValue(Texture("skull", ext: "jpg", origin: .bottomLeft), forKey: .skull)
    }
    
    static subscript(_ type: TextureTypes) -> MTLTexture?
    {
        return textures[type]?.texture
    }
}

class Texture
{
    private (set) var texture: MTLTexture!
    
    init(_ textureName: String, ext: String = "png", origin: MTKTextureLoader.Origin = .topLeft)
    {
        let textureLoader = TextureLoader(name: textureName, fileExtension: ext, origin: origin)
        let texture: MTLTexture = textureLoader.loadFromBundle()
        
        setTexture(texture)
    }
    
    private func setTexture(_ texture: MTLTexture)
    {
        self.texture = texture
    }
}

class TextureLoader
{
    private var fileName: String
    private var fileExtension: String
    private var origin: MTKTextureLoader.Origin
    
    init(name: String, fileExtension: String = "png", origin: MTKTextureLoader.Origin = .topLeft)
    {
        self.fileName = name
        self.fileExtension = fileExtension
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

