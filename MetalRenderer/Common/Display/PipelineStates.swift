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
    
    private (set) var skybox: MTLRenderPipelineState!
    private (set) var worldMeshLightmapped: MTLRenderPipelineState!
    private (set) var worldMeshVertexlit: MTLRenderPipelineState!
    private (set) var skeletalMesh: MTLRenderPipelineState!
    private (set) var billboards: MTLRenderPipelineState!
    private (set) var particles: MTLRenderPipelineState!
    private (set) var userInterface: MTLRenderPipelineState!
    
    private (set) var simpleGrid: MTLRenderPipelineState!
    
    private (set) var brush: MTLRenderPipelineState!
    
    init()
    {
        createSkyboxPipelineState()
        createWorldMeshLightmappedPipelineState()
        createWorldMeshVertexlitPipelineState()
        createSkeletalMeshPipelineState()
        
        createBasicPipelineState()
        createBasicInstPipelineState()
        
        createBillboardsPipelineState()
        createParticlesPipelineState()
        
        createUserInterfacePipelineState()
        
        createSimpleGridPipelineState()
        
        createBrushPipelineState()
    }
    
    private func createSkyboxPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "skybox_vertex_shader")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "skybox_fragment_shader")

        descriptor.label = "Skybox Pipeline State"

        skybox = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createWorldMeshLightmappedPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "world_mesh_vs")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "world_mesh_lightmapped_fs")
        descriptor.vertexDescriptor = WorldStaticMesh.vertexDescriptor()

        descriptor.label = "World Mesh Lightmapped Pipeline State"

        worldMeshLightmapped = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createWorldMeshVertexlitPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "world_mesh_vs")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "world_mesh_vertexlit_fs")
        descriptor.vertexDescriptor = WorldStaticMesh.vertexDescriptor()

        descriptor.label = "World Mesh Vertexlit Pipeline State"

        worldMeshVertexlit = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createSkeletalMeshPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "skeletal_mesh_vs")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "skeletal_mesh_fs")
        descriptor.vertexDescriptor = SkeletalMesh.vertexDescriptor()

        descriptor.label = "Skeletal Mesh Pipeline State"

        skeletalMesh = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createBasicPipelineState()
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

        basic = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createBasicInstPipelineState()
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

        basicInst = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createBillboardsPipelineState()
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

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "billboard_vs")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "billboard_fs")
        descriptor.vertexDescriptor = particleVertexDescriptor()

        descriptor.label = "Billboards Render Pipeline State"

        billboards = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createParticlesPipelineState()
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

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "particle_vs")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "particle_fs")
        descriptor.vertexDescriptor = particleVertexDescriptor()

        descriptor.label = "Particles Render Pipeline State"

        particles = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createUserInterfacePipelineState()
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

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "user_interface_vs")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "user_interface_fs")
        descriptor.vertexDescriptor = basicVertexDescriptor()

        descriptor.label = "UI Render Pipeline State"

        userInterface = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createSimpleGridPipelineState()
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

        simpleGrid = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createBrushPipelineState()
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

        brush = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
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
