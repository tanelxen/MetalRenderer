//
//  VertexDescriptorLibrary.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

enum VertexDescriptorTypes
{
    case basic
}

enum VertexDescriptorLibrary
{
    private static var descriptors: [VertexDescriptorTypes: VertexDescriptor] = [:]
    
    static func initialize()
    {
        descriptors.updateValue(BasicVertexDescriptor(), forKey: .basic)
    }
    
    static func descriptor(_ type: VertexDescriptorTypes) -> MTLVertexDescriptor
    {
        descriptors[type]!.descriptor
    }
}

protocol VertexDescriptor
{
    var name: String { get }
    var descriptor: MTLVertexDescriptor { get }
}

struct BasicVertexDescriptor: VertexDescriptor
{
    var name: String = "Basic Vertex Descriptor"
    var descriptor: MTLVertexDescriptor
    
    init()
    {
        descriptor = MTLVertexDescriptor()
        
        var offset: Int = 0
        
        // Position
        descriptor.attributes[0].format = .float3
        descriptor.attributes[0].bufferIndex = 0
        descriptor.attributes[0].offset = offset
        offset += float3.size
        
        // UV
        descriptor.attributes[1].format = .float2
        descriptor.attributes[1].bufferIndex = 0
        descriptor.attributes[1].offset = offset
        offset += float2.size
        
        // Normal
        descriptor.attributes[2].format = .float3
        descriptor.attributes[2].bufferIndex = 0
        descriptor.attributes[2].offset = offset
        offset += float3.size
        
        // Tangent
        descriptor.attributes[3].format = .float3
        descriptor.attributes[3].bufferIndex = 0
        descriptor.attributes[3].offset = offset
        offset += float3.size
        
        descriptor.layouts[0].stride = Vertex.stride
    }
}
