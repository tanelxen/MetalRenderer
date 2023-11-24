//
//  WorldStaticMesh.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 30.09.2023.
//

import Foundation
import Metal

final class WorldStaticMesh
{
    private var vertexBuffer: MTLBuffer?
    private var indexBuffer: MTLBuffer?
    
    private var surfaces: [WorldMeshSurface] = []
    private var lightmap: MTLTexture?
    
    func loadFromAsset(_ asset: WorldStaticMeshAsset)
    {
        let vertices = asset.vertices.map {
            WorldMeshVertex(position: $0.position, texCoord0: $0.texCoord0, texCoord1: $0.texCoord1, color: $0.color)
        }
        
        vertexBuffer = Engine.device.makeBuffer(bytes: vertices,
                                                length: vertices.count * MemoryLayout<WorldMeshVertex>.stride,
                                                options: [])
        
        indexBuffer = Engine.device.makeBuffer(bytes: asset.indices,
                                               length: asset.indices.count * MemoryLayout<UInt32>.stride,
                                               options: [])
        
        for surface in asset.surfaces
        {
            let textureName = asset.textures[surface.textureIndex]
            let texture = TextureManager.shared.getTexture(for: "Assets/" + textureName) ?? TextureManager.shared.devTexture
            
            let lightmapped = WorldMeshSurface(
                texture: texture,
                indexCount: surface.indexCount,
                indexOffset: surface.firstIndex * MemoryLayout<UInt32>.stride,
                useLightmap: surface.isLightmapped
            )
            
            surfaces.append(lightmapped)
        }
    }
    
    func setLightmap(_ texture: MTLTexture?)
    {
        lightmap = texture
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
    
    func renderLightmapped(with encoder: MTLRenderCommandEncoder)
    {
        guard let indexBuffer = self.indexBuffer else { return }
        
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(lightmap, index: 1)
        
        for surface in surfaces
        {
            encoder.setFragmentTexture(surface.texture, index: 0)
            
            var useLightmap = surface.useLightmap
            encoder.setFragmentBytes(&useLightmap, length: MemoryLayout<Bool>.size, index: 0)
            
            encoder.drawIndexedPrimitives(type: .triangle,
                                          indexCount: surface.indexCount,
                                          indexType: .uint32,
                                          indexBuffer: indexBuffer,
                                          indexBufferOffset: surface.indexOffset)
        }
    }
}

private struct WorldMeshVertex
{
    let position: SIMD3<Float>
    let texCoord0: SIMD2<Float>
    let texCoord1: SIMD2<Float>
    let color: SIMD3<Float>
}

private struct WorldMeshSurface
{
    let texture: MTLTexture?
    let indexCount: Int
    let indexOffset: Int
    let useLightmap: Bool
}
