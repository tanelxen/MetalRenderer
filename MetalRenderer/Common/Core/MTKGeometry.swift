//
//  MTKPlane.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 30.04.2024.
//

import MetalKit

class MTKGeometry
{
    private let state: MTLRenderPipelineState
    private let mesh: MTKMesh
    
    enum MeshType {
        case box, boxWired, sphere
    }
    
    var vertexBuffer: MTLBuffer? {
        mesh.vertexBuffers.first?.buffer
    }
    
    var vertexCount: Int {
        mesh.vertexCount
    }
    
    var indexBuffer: MTLBuffer? {
        mesh.submeshes.first?.indexBuffer.buffer
    }
    
    var indexCount: Int {
        mesh.submeshes.first?.indexCount ?? 0
    }
    
    init(_ type: MeshType, extents: float3 = .one)
    {
        let allocator = MTKMeshBufferAllocator(device: Engine.device)
        
        let mdlMesh: MDLMesh
        
        switch type {
            case .box:
                mdlMesh = MDLMesh(
                    boxWithExtent: extents,
                    segments: [1, 1, 1],
                    inwardNormals: false,
                    geometryType: .triangles,
                    allocator: allocator
                )
                
            case .boxWired:
                mdlMesh = MDLMesh(
                    boxWithExtent: extents,
                    segments: [1, 1, 1],
                    inwardNormals: false,
                    geometryType: .lines,
                    allocator: allocator
                )
                
            case .sphere:
                mdlMesh = MDLMesh(
                    sphereWithExtent: extents,
                    segments: [12, 12],
                    inwardNormals: false,
                    geometryType: .triangles,
                    allocator: allocator
                )
        }
        
        let vertexDescriptor = MTKModelIOVertexDescriptorFromMetal(Self.brushVertexDescriptor())
                
        // Indicate how each Metal vertex descriptor attribute maps to each ModelIO attribute
        if let attribute = vertexDescriptor.attributes[0] as? MDLVertexAttribute {
            attribute.name = MDLVertexAttributePosition
        }
        
        if let attribute = vertexDescriptor.attributes[1] as? MDLVertexAttribute {
            attribute.name = MDLVertexAttributeNormal
        }
        
        if let attribute = vertexDescriptor.attributes[2] as? MDLVertexAttribute {
            attribute.name = MDLVertexAttributeTextureCoordinate
        }
        
        mdlMesh.vertexDescriptor = vertexDescriptor
        
        mesh = try! MTKMesh(mesh: mdlMesh, device: Engine.device)
        
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat
        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "box_vs")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "brush_fs")
        descriptor.vertexDescriptor = Self.brushVertexDescriptor()

        state = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private class func brushVertexDescriptor() -> MTLVertexDescriptor
    {
        let descriptor = MTLVertexDescriptor()
        var offset = 0
        
        // Position
        descriptor.attributes[0].offset = offset
        descriptor.attributes[0].format = .float3
        descriptor.attributes[0].bufferIndex = 0
        offset += MemoryLayout<float3>.size
        
        // Normal
        descriptor.attributes[1].offset = offset
        descriptor.attributes[1].format = .float3
        descriptor.attributes[1].bufferIndex = 0
        offset += MemoryLayout<float3>.size
        
        // UV
        descriptor.attributes[2].offset = offset
        descriptor.attributes[2].format = .float2
        descriptor.attributes[2].bufferIndex = 0
        offset += MemoryLayout<float2>.size
        
        descriptor.layouts[0].stepFunction = .perVertex
        descriptor.layouts[0].stride = offset
        
        return descriptor
    }
    
    func render(with encoder: MTLRenderCommandEncoder)
    {
        // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
        encoder.pushDebugGroup("MTKGeometry")
        
        encoder.setCullMode(.back)
        encoder.setFrontFacing(.clockwise)
        encoder.setRenderPipelineState(state)
        
        // Set mesh's vertex buffers
        for i in mesh.vertexBuffers.indices
        {
            let vertexBuffer = mesh.vertexBuffers[i]
            encoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: i)
        }
        
        // Draw each submesh of our mesh
        for submesh in mesh.submeshes
        {
            encoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                          indexCount: submesh.indexCount,
                                          indexType: submesh.indexType,
                                          indexBuffer: submesh.indexBuffer.buffer,
                                          indexBufferOffset: submesh.indexBuffer.offset)
        }
        
        encoder.popDebugGroup()
    }
}
