//
//  NavMesh.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 26.12.2022.
//

//import simd
//import ModelIO
//import MetalKit
//
//struct FaceNavMesh
//{
//    let indexCount: Int
//    let indexBuffer: MTLBuffer
//    
//    func renderWithEncoder(_ encoder: MTLRenderCommandEncoder)
//    {
//        encoder.drawIndexedPrimitives(type: .triangle,
//                                      indexCount: indexCount,
//                                      indexType: .uint32,
//                                      indexBuffer: indexBuffer,
//                                      indexBufferOffset: 0)
//    }
//}
//
//class NavMesh
//{
//    let device: MTLDevice
//    let map: Q3Map
//
//    var vertexBuffer: MTLBuffer! = nil
//    var faceMeshes: Array<FaceNavMesh> = []
//    
//    init(device: MTLDevice, map: Q3Map)
//    {
//        self.device = device
//        self.map = map
//        
//        for face in map.faces
//        {
//            
//            
//            for i in face.vertexIndices
//        }
//        
//        vertexBuffer = device.makeBuffer(bytes: map.vertices, length: map.vertices.count * MemoryLayout<Q3Vertex>.size, options: MTLResourceOptions())
//        
//        for (key, indices) in groupedIndices
//        {
//            let url = URL(fileURLWithPath: "Contents/Resources/" + key.texture + ".jpg", relativeTo: Bundle.main.bundleURL)
//            
//            let texture = TextureManager.shared.getTexture(url: url) ?? devTexture
//
//            let lightmap = key.lightmap >= 0
//                ? TextureManager.shared.loadLightmap(map.lightmaps[key.lightmap])
//                : TextureManager.shared.whiteTexture()
//            
//            let buffer = device.makeBuffer(bytes: indices,
//                                           length: indices.count * MemoryLayout<UInt32>.size,
//                                           options: MTLResourceOptions())
//            
//            let faceMesh = FaceMesh(texture: texture, lightmap: lightmap, indexCount: indices.count, indexBuffer: buffer!)
//            
//            faceMeshes.append(faceMesh)
//        }
//    }
//    
//    func renderWithEncoder(_ encoder: MTLRenderCommandEncoder)
//    {
//        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//        
//        for faceMesh in faceMeshes
//        {
//            faceMesh.renderWithEncoder(encoder)
//        }
//    }
//    
//    static func vertexDescriptor() -> MTLVertexDescriptor
//    {
//        let descriptor = MTLVertexDescriptor()
//        var offset = 0
//        
//        // Position
//        descriptor.attributes[0].offset = offset
//        descriptor.attributes[0].format = .float4
//        descriptor.attributes[0].bufferIndex = 0
//        offset += MemoryLayout<float4>.size
//        
//        // Normal
//        descriptor.attributes[1].offset = offset
//        descriptor.attributes[1].format = .float4
//        descriptor.attributes[1].bufferIndex = 0
//        offset += MemoryLayout<float4>.size
//        
//        // Color
//        descriptor.attributes[2].offset = offset
//        descriptor.attributes[2].format = .float4
//        descriptor.attributes[2].bufferIndex = 0
//        offset += MemoryLayout<float4>.size
//        
//        // Texure Coordinates
//        descriptor.attributes[3].offset = offset
//        descriptor.attributes[3].format = .float2
//        descriptor.attributes[3].bufferIndex = 0
//        offset += MemoryLayout<float2>.size
//        
//        // Lightmap Coordinates
//        descriptor.attributes[4].offset = offset
//        descriptor.attributes[4].format = .float2
//        descriptor.attributes[4].bufferIndex = 0
//        offset += MemoryLayout<float2>.size
//        
//        descriptor.layouts[0].stepFunction = .perVertex
//        descriptor.layouts[0].stride = offset
//        
//        return descriptor
//    }
//}
//
//
