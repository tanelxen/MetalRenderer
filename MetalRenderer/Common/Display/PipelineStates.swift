//
//  PipelineStates.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 26.03.2023.
//

import MetalKit

class PipelineStates
{
    private (set) var basic: MTLRenderPipelineState!
    private (set) var basicInst: MTLRenderPipelineState!
    
    private (set) var simpleGrid: MTLRenderPipelineState!
    
    private (set) var brush: MTLRenderPipelineState!
    private (set) var dot: MTLRenderPipelineState!
    
    init()
    {
        basic = createBasicPipelineState()
        basicInst = createBasicInstPipelineState()

        simpleGrid = createSimpleGridPipelineState()
        
        brush = createBrushPipelineState()
        dot = createDotPipelineState()
    }
    
    private func createBasicPipelineState() -> MTLRenderPipelineState?
    {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "basic_vs")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "basic_fs")
        descriptor.vertexDescriptor = basicVertexDescriptor()

        descriptor.label = "Basic Render Pipeline State"

        return try? Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createBasicInstPipelineState() -> MTLRenderPipelineState?
    {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "basic_inst_vs")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "basic_fs")
        descriptor.vertexDescriptor = basicVertexDescriptor()

        descriptor.label = "Basic Instanced Render Pipeline State"

        return try? Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createSimpleGridPipelineState() -> MTLRenderPipelineState?
    {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "simple_grid_vs")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "simple_grid_fs")
        descriptor.vertexDescriptor = basicVertexDescriptor()

        descriptor.label = "Simple Grid Pipeline State"

        return try? Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createBrushPipelineState() -> MTLRenderPipelineState?
    {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "brush_vs")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "brush_fs")
        descriptor.vertexDescriptor = brushVertexDescriptor()

        descriptor.label = "Simple Grid Pipeline State"

        return try? Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createDotPipelineState() -> MTLRenderPipelineState?
    {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "editor_dot_vs")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "editor_dot_fs")
        descriptor.vertexDescriptor = brushVertexDescriptor()

        descriptor.label = "Editor Dot Pipeline State"

        return try? Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func basicVertexDescriptor() -> MTLVertexDescriptor
    {
        let descriptor = MTLVertexDescriptor()
        var offset = 0
        
        // Position
        descriptor.attributes[0].offset = offset
        descriptor.attributes[0].format = .float3
        descriptor.attributes[0].bufferIndex = 0
        offset += MemoryLayout<float3>.size
        
        // Texture Coordinates
        descriptor.attributes[1].offset = offset
        descriptor.attributes[1].format = .float2
        descriptor.attributes[1].bufferIndex = 0
        offset += MemoryLayout<float2>.size
        
        descriptor.layouts[0].stepFunction = .perVertex
        descriptor.layouts[0].stride = offset
        
        return descriptor
    }
    
    private func particleVertexDescriptor() -> MTLVertexDescriptor
    {
        let descriptor = MTLVertexDescriptor()
        var offset = 0
        
        // Position
        descriptor.attributes[0].offset = offset
        descriptor.attributes[0].format = .float3
        descriptor.attributes[0].bufferIndex = 0
        offset += MemoryLayout<float3>.size
        
        // Color
        descriptor.attributes[1].offset = offset
        descriptor.attributes[1].format = .float4
        descriptor.attributes[1].bufferIndex = 0
        offset += MemoryLayout<float4>.size
        
        // Size
        descriptor.attributes[1].offset = offset
        descriptor.attributes[1].format = .float
        descriptor.attributes[1].bufferIndex = 0
        offset += MemoryLayout<Float>.size
        
        descriptor.layouts[0].stepFunction = .perVertex
        descriptor.layouts[0].stride = offset
        
        return descriptor
    }
    
    private func brushVertexDescriptor() -> MTLVertexDescriptor
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
        
        // Color
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
}
