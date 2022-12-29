//
//  BSPMesh.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 07.02.2022.
//

import simd
import ModelIO
import MetalKit

struct IndexGroupKey: Hashable
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

func ==(lhs: IndexGroupKey, rhs: IndexGroupKey) -> Bool
{
    return lhs.texture == rhs.texture && lhs.lightmap == rhs.lightmap
}

struct FaceMesh
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

class BSPMesh
{
    let device: MTLDevice
    let map: Q3Map

    var vertexBuffer: MTLBuffer! = nil
    var faceMeshes: Array<FaceMesh> = []
    
    var facedUpCount = 0
    var facedUpIndiciesBuffer: MTLBuffer! = nil
    var facedUpVertexBuffer: MTLBuffer! = nil
    
    init(device: MTLDevice, map: Q3Map)
    {
        self.device = device
        self.map = map
        
        let assetURL = Bundle.main.url(forResource: "dev_256", withExtension: "jpeg")!
        let devTexture = TextureManager.shared.getTexture(url: assetURL, origin: .topLeft)!
        
        var groupedIndices: Dictionary<IndexGroupKey, [UInt32]> = Dictionary()
        
        for face in map.faces
        {
            if (face.textureName == "noshader") { continue }
            
            let key = IndexGroupKey(
                texture: face.textureName,
                lightmap: face.lightmapIndex
            )
            
            // Ensure we have an array to append to
            if groupedIndices[key] == nil {
                groupedIndices[key] = []
            }
            
            groupedIndices[key]?.append(contentsOf: face.vertexIndices)
        }
        
        vertexBuffer = device.makeBuffer(bytes: map.vertices, length: map.vertices.count * MemoryLayout<Q3Vertex>.size, options: MTLResourceOptions())
        
        var facedUp: [UInt32] = []
        
        for (key, indices) in groupedIndices
        {
            let url = URL(fileURLWithPath: "Contents/Resources/" + key.texture + ".jpg", relativeTo: Bundle.main.bundleURL)
            
            let texture = TextureManager.shared.getTexture(url: url) ?? devTexture

            let lightmap = key.lightmap >= 0
                ? TextureManager.shared.loadLightmap(map.lightmaps[key.lightmap])
                : TextureManager.shared.whiteTexture()
            
            let buffer = device.makeBuffer(bytes: indices,
                                           length: indices.count * MemoryLayout<UInt32>.size,
                                           options: MTLResourceOptions())
            
            let faceMesh = FaceMesh(texture: texture, lightmap: lightmap, indexCount: indices.count, indexBuffer: buffer!)
            
            faceMeshes.append(faceMesh)
            
            var i = 0

            while i < indices.count
            {
                let i0 = Int(indices[i + 0])
                let v0 = map.vertices[i0].position

                let i1 = Int(indices[i + 1])
                let v1 = map.vertices[i1].position

                let i2 = Int(indices[i + 2])
                let v2 = map.vertices[i2].position

                if isFacedUp(v0: v0, v1: v1, v2: v2) && v0.z < 8
                {
                    facedUp.append(contentsOf: [indices[i + 0], indices[i + 1], indices[i + 2]])
                }

                i += 3
            }
        }
        
        typealias VertexPair = (float3, UInt32)
        var vertexPairs: [VertexPair] = []
        
        var indicies: [UInt32] = []
        
        for originalIndex in facedUp
        {
            if let index = vertexPairs.firstIndex(where: { $0.1 == originalIndex })
            {
                indicies.append(UInt32(index))
            }
            else
            {
                let pos = map.vertices[Int(originalIndex)].position
                let new = (pos, originalIndex)
                
                indicies.append(UInt32(vertexPairs.count))
                vertexPairs.append(new)
            }
        }
        
        facedUpCount = indicies.count
        facedUpIndiciesBuffer = device.makeBuffer(bytes: indicies,
                                          length: indicies.count * MemoryLayout<UInt32>.size,
                                          options: MTLResourceOptions())
        
        let vertices = vertexPairs.map { $0.0 }
        
        facedUpVertexBuffer = device.makeBuffer(bytes: vertices,
                                                length: vertices.count * MemoryLayout<float3>.size,
                                                options: MTLResourceOptions())
        
        
    }
    
    func renderWithEncoder(_ encoder: MTLRenderCommandEncoder)
    {
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        for faceMesh in faceMeshes
        {
            faceMesh.renderWithEncoder(encoder)
        }
    }
    
    func renderFacedUp(_ encoder: MTLRenderCommandEncoder)
    {
        var modelConstants = ModelConstants()
        modelConstants.modelMatrix.translate(direction: float3(0, 0, 0.2))
        modelConstants.color = float3(0.3, 0.3, 0.3)
        
        encoder.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
        
        encoder.setVertexBuffer(facedUpVertexBuffer, offset: 0, index: 0)
        
        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: facedUpCount,
                                      indexType: .uint32,
                                      indexBuffer: facedUpIndiciesBuffer,
                                      indexBufferOffset: 0)
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

func isFacedUp(v0: float3, v1: float3, v2: float3) -> Bool
{
    let normal = normalize(cross(v1 - v0, v1 - v2))
    
    return dot(normal, .z_axis) > 0.99
}
