//
//  BSPMesh.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.02.2022.
//

import simd
import MetalKit

class BSPMesh
{
    private let map: Q3Map
    private var vertexBuffer: MTLBuffer! = nil
    private var faceMeshes: Array<FaceMesh> = []
    
    init(map: Q3Map)
    {
        self.map = map
        
        var groupedIndices: Dictionary<IndexGroupKey, [UInt32]> = Dictionary()
        
        for face in map.faces
        {
            if (face.textureName == "noshader") { continue }
            
            let key = IndexGroupKey(
                texture: face.textureName,
                lightmap: face.lightmapIndex
            )
            
            if groupedIndices[key] == nil {
                groupedIndices[key] = []
            }
            
            groupedIndices[key]?.append(contentsOf: face.vertexIndices)
        }
        
        vertexBuffer = Engine.device.makeBuffer(bytes: map.vertices,
                                                length: map.vertices.count * MemoryLayout<Q3Vertex>.size,
                                                options: [])
        
        for (key, indices) in groupedIndices
        {
            let texture = TextureManager.shared.getTexture(for: "Assets/q3/" + key.texture) ?? TextureManager.shared.devTexture!

            let lightmap = key.lightmap >= 0
                ? TextureManager.shared.loadLightmap(map.lightmaps[key.lightmap])
                : TextureManager.shared.whiteTexture()
            
            let buffer = Engine.device.makeBuffer(bytes: indices,
                                                  length: indices.count * MemoryLayout<UInt32>.size,
                                                  options: [])
            
            let faceMesh = FaceMesh(texture: texture, lightmap: lightmap, indexCount: indices.count, indexBuffer: buffer!)
            
            faceMeshes.append(faceMesh)
        }
    }
    
    func renderWithEncoder(_ encoder: MTLRenderCommandEncoder)
    {
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        for faceMesh in faceMeshes
        {
            faceMesh.renderWithEncoder(encoder)
        }
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
        
        descriptor.layouts[0].stepFunction = .perVertex
        descriptor.layouts[0].stride = offset
        
        return descriptor
    }
}

private struct IndexGroupKey: Hashable
{
    let texture: String
    let lightmap: Int
    
    var hashValue: Int {
        return texture.hashValue ^ lightmap.hashValue
    }
    
    func hash(into hasher: inout Hasher)
    {
        let value = texture.hashValue ^ lightmap.hashValue
        hasher.combine(value)
    }
}

private func ==(lhs: IndexGroupKey, rhs: IndexGroupKey) -> Bool
{
    return lhs.texture == rhs.texture && lhs.lightmap == rhs.lightmap
}

private struct FaceMesh
{
    let texture: MTLTexture
    let lightmap: MTLTexture
    let indexCount: Int
    let indexBuffer: MTLBuffer
    
    func renderWithEncoder(_ encoder: MTLRenderCommandEncoder)
    {
        encoder.setFragmentTexture(texture, index: 0)
        encoder.setFragmentTexture(lightmap, index: 1)
        
        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: indexCount,
                                      indexType: .uint32,
                                      indexBuffer: indexBuffer,
                                      indexBufferOffset: 0)
    }
}
