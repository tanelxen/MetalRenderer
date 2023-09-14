//
//  PipelineStates.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 26.03.2023.
//

import MetalKit

class PipelineStates
{
    private (set) var skybox: MTLRenderPipelineState!
    private (set) var worldMeshLightmapped: MTLRenderPipelineState!
    private (set) var worldMeshVertexlit: MTLRenderPipelineState!
    private (set) var skeletalMesh: MTLRenderPipelineState!
    private (set) var solidColor: MTLRenderPipelineState!
    private (set) var solidColorInst: MTLRenderPipelineState!
    private (set) var particles: MTLRenderPipelineState!
    private (set) var ui: MTLRenderPipelineState!
    
    init()
    {
        createSkyboxPipelineState()
        createWorldMeshLightmappedPipelineState()
        createWorldMeshVertexlitPipelineState()
        createSkeletalMeshPipelineState()
        
        createSolidColorPipelineState()
        createSolidColorInstPipelineState()
        
        createParticlesPipelineState()
        
        createUIPipelineState()
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
        descriptor.vertexDescriptor = BSPMesh.vertexDescriptor()

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
        descriptor.vertexDescriptor = BSPMesh.vertexDescriptor()

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
    
    private func createSolidColorPipelineState()
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

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "solid_color_vs")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "solid_color_fs")

        descriptor.label = "Solid Color Render Pipeline State"

        solidColor = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createSolidColorInstPipelineState()
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

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "solid_color_inst_vs")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "solid_color_fs")

        descriptor.label = "Solid Color Render Pipeline State"

        solidColorInst = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
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

        descriptor.label = "Particles Render Pipeline State"

        particles = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createUIPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "ui_vs")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "solid_color_fs")

        descriptor.label = "UI Render Pipeline State"

        ui = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
}
