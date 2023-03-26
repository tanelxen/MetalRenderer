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
    
    init()
    {
        createSkyboxPipelineState()
        createWorldMeshLightmappedPipelineState()
        createWorldMeshVertexlitPipelineState()
        createSkeletalMeshPipelineState()
        createSolidColorPipelineState()
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
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "solid_color_vs")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "solid_color_fs")

        descriptor.label = "Solid Color Render Pipeline State"

        solidColor = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
}
