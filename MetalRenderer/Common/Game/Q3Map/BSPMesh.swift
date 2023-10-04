//
//  BSPMesh.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.02.2022.
//

import MetalKit
import Quake3BSP

class BSPMesh
{
    private let map: Q3Map
    private var vertexBuffer: MTLBuffer?
    private var lightmappedFaces: [LightmappedMesh] = []
    private var vertexlitFaces: [VertexlitMesh] = []
    
    private var lightmapAtlas = LightmapAtlas()
    private var lightmap: MTLTexture?
    
    init(map: Q3Map)
    {
        self.map = map
        
        makeLightmapsAtlas()
        adjustForLightmapAtlas()
        
        let lenght = map.vertices.count * MemoryLayout<Q3Vertex>.size
        vertexBuffer = Engine.device.makeBuffer(bytes: map.vertices, length: lenght)
        
        lightmap = uploadLightmap(lightmapAtlas)
        
        createLightmappedFaces()
        createVertexlitFaces()
    }
    
    func renderLightmapped(with encoder: MTLRenderCommandEncoder)
    {
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(lightmap, index: 1)
        
        for mesh in lightmappedFaces
        {
            mesh.render(with: encoder)
        }
    }
    
    func renderVertexlit(with encoder: MTLRenderCommandEncoder)
    {
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        for mesh in vertexlitFaces
        {
            mesh.render(with: encoder)
        }
    }
    
    private func createLightmappedFaces()
    {
        var groupedIndices: Dictionary<String, [UInt32]> = Dictionary()
        
        for face in map.faces
        {
            if face.textureName == "noshader" { continue }
            if face.textureName.contains("sky") { continue }
            if face.type == .mesh { continue }
            
            let key = face.textureName
            
            if groupedIndices[key] == nil {
                groupedIndices[key] = []
            }
            
            groupedIndices[key]?.append(contentsOf: face.vertexIndices)
        }
        
        for (texture, indices) in groupedIndices
        {
            let texture = TextureManager.shared.getTexture(for: "Assets/q3/" + texture) ?? TextureManager.shared.devTexture!
            
            let lenght = indices.count * MemoryLayout<UInt32>.size
            let buffer = Engine.device.makeBuffer(bytes: indices, length: lenght)
            
            let mesh = LightmappedMesh(texture: texture,
                                       indexCount: indices.count,
                                       indexBuffer: buffer!)
            
            lightmappedFaces.append(mesh)
        }
    }
    
    private func createVertexlitFaces()
    {
        var groupedIndices: Dictionary<String, [UInt32]> = Dictionary()
        
        for face in map.faces
        {
            if face.textureName == "noshader" { continue }
            if face.textureName.contains("sky") { continue }
            if face.type != .mesh { continue }
            
            let key = face.textureName
            
            if groupedIndices[key] == nil {
                groupedIndices[key] = []
            }
            
            groupedIndices[key]?.append(contentsOf: face.vertexIndices)
        }
        
        for (texture, indices) in groupedIndices
        {
            let texture = TextureManager.shared.getTexture(for: "Assets/q3/" + texture) ?? TextureManager.shared.devTexture!
            
            let lenght = indices.count * MemoryLayout<UInt32>.size
            let buffer = Engine.device.makeBuffer(bytes: indices, length: lenght)
            
            let mesh = VertexlitMesh(texture: texture,
                                     indexCount: indices.count,
                                     indexBuffer: buffer!)
            
            vertexlitFaces.append(mesh)
        }
    }
    
    private func uploadLightmap(_ atlas: LightmapAtlas) -> MTLTexture?
    {
        guard atlas.width > 0 || atlas.height > 0
        else {
            return nil
        }
        
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                            width: atlas.width,
                                                            height: atlas.height,
                                                            mipmapped: true)
        
        guard let texture = Engine.device.makeTexture(descriptor: desc)
        else {
            return nil
        }
        
        for part in atlas.parts
        {
            let region = MTLRegionMake2D(part.x, part.y, part.width, part.height)
            let bytesPerRow = part.width * atlas.bytesPerComponent
            
            texture.replace(region: region,
                            mipmapLevel: 0,
                            withBytes: part.bytes,
                            bytesPerRow: bytesPerRow)
        }
        
        TextureManager.shared.generateMipmaps(texture)
        
        return texture
    }
    
    static func vertexDescriptor() -> MTLVertexDescriptor
    {
        let descriptor = MTLVertexDescriptor()
        var offset = 0
        
        // Position
        descriptor.attributes[0].offset = offset
        descriptor.attributes[0].format = .float3
        descriptor.attributes[0].bufferIndex = 0
        offset += MemoryLayout<float3>.size
        
        // Texure Coordinates
        descriptor.attributes[1].offset = offset
        descriptor.attributes[1].format = .float2
        descriptor.attributes[1].bufferIndex = 0
        offset += MemoryLayout<float2>.size
        
        // Lightmap Coordinates
        descriptor.attributes[2].offset = offset
        descriptor.attributes[2].format = .float2
        descriptor.attributes[2].bufferIndex = 0
        offset += MemoryLayout<float2>.size
        
        // Color
        descriptor.attributes[3].offset = offset
        descriptor.attributes[3].format = .float3
        descriptor.attributes[3].bufferIndex = 0
        offset += MemoryLayout<float3>.size
        
        descriptor.layouts[0].stepFunction = .perVertex
        descriptor.layouts[0].stride = offset
        
        return descriptor
    }
    
    private func makeLightmapsAtlas()
    {
        let count = map.lightmaps.count
        let gridSize = Int(ceil(sqrt(Float(count))))
        
        let textureSize = gridSize * 128
            
        var xOffset: Int = 0
        var yOffset: Int = 0
        
        lightmapAtlas.width = gridSize * 128
        lightmapAtlas.height = gridSize * 128
        lightmapAtlas.bytesPerComponent = 4
        
        for i in 0 ..< count
        {
            lightmapAtlas.parts.append(
                Lightmap(
                    x: xOffset,
                    y: yOffset,
                    width: 128,
                    height: 128,
                    bytes: map.lightmaps[i].flatMap({ [$0.0, $0.1, $0.2, $0.3] })
                )
            )
            
            xOffset += 128
            
            if xOffset >= textureSize
            {
                yOffset += 128
                xOffset = 0
            }
        }
    }
    
    private func adjustForLightmapAtlas()
    {
        var processedVertices = Array<Bool>.init(repeating: false, count: map.vertices.count)
        
        for face in map.faces
        {
            guard face.lightmapIndex >= 0 else { continue }

            let lm = lightmapAtlas.parts[face.lightmapIndex]
            let width = Float(lightmapAtlas.width)
            let height = Float(lightmapAtlas.height)

            for i in face.vertexIndices.map({ Int($0) })
            {
                if processedVertices[i] { continue }
                
                map.vertices[i].lightmapCoord.x = (map.vertices[i].lightmapCoord.x * Float(lm.width) + Float(lm.x)) / width
                map.vertices[i].lightmapCoord.y = (map.vertices[i].lightmapCoord.y * Float(lm.height) + Float(lm.y)) / height
                
                processedVertices[i] = true
            }
        }
    }
}

private struct LightmappedMesh
{
    let texture: MTLTexture
    let indexCount: Int
    let indexBuffer: MTLBuffer
    
    func render(with encoder: MTLRenderCommandEncoder)
    {
        encoder.setFragmentTexture(texture, index: 0)
        
        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: indexCount,
                                      indexType: .uint32,
                                      indexBuffer: indexBuffer,
                                      indexBufferOffset: 0)
    }
}

private struct VertexlitMesh
{
    let texture: MTLTexture
    let indexCount: Int
    let indexBuffer: MTLBuffer
    
    func render(with encoder: MTLRenderCommandEncoder)
    {
        encoder.setFragmentTexture(texture, index: 0)
        
        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: indexCount,
                                      indexType: .uint32,
                                      indexBuffer: indexBuffer,
                                      indexBufferOffset: 0)
    }
}

struct LightmapAtlas
{
    var width: Int = 0
    var height: Int = 0
    var bytesPerComponent: Int = 0
    var parts: [Lightmap] = []
}

struct Lightmap
{
    let x, y: Int
    let width, height: Int
    let bytes: [UInt8]
}

/*
 unsigned char* source = new unsigned char[ 128 * 128 * 4 ]; // in reality, comes from your texture loader
 unsigned char* target = new unsigned char[ 512 * 512 * 4 ];

 int targetX = 128;
 int targetY = 0;

 for(int sourceY = 0; sourceY < 128; ++sourceY) {
     for(int sourceX = 0; sourceX < 128; ++sourceX) {
         int from = (sourceY * 128 * 4) + (sourceX * 4); // 4 bytes per pixel (assuming RGBA)
         int to = ((targetY + sourceY) * 512 * 4) + ((targetX + sourceX) * 4); // same format as source

         for(int channel = 0; channel < 4; ++channel) {
             target[to + channel] = source[from + channel];
         }
     }
 }
 */
