//
//  GeometryRenderPass.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.02.2022.
//

import MetalKit

class GeometryRenderPass
{
    private (set) var gAlbedoTexture: MTLTexture!
    private (set) var gNormalTexture: MTLTexture!
    private (set) var gPositionTexture: MTLTexture!
    private (set) var gDepthTexture: MTLTexture!
    private (set) var lightingTexture: MTLTexture!
    
    private (set) var passDescriptor: MTLRenderPassDescriptor!
    
    private (set) var bspPipelineState: MTLRenderPipelineState!
    private (set) var staticPipelineState: MTLRenderPipelineState!
    private (set) var skeletalPipelineState: MTLRenderPipelineState!
    
    private var width: Int = 1
    private var height: Int = 1
    
    init()
    {
        createBspPipelineState()
    }
    
    func setup(for size: CGSize)
    {
        self.width = Int(size.width)
        self.height = Int(size.height)
        
        setupAlbedo()
        setupNormal()
        setupPosition()
        setupDepth()
        setupLighting()
        
        passDescriptor = MTLRenderPassDescriptor()
        
        passDescriptor.colorAttachments[0].texture = gAlbedoTexture
        passDescriptor.colorAttachments[0].loadAction = .clear
        passDescriptor.colorAttachments[0].storeAction = .store
        
        passDescriptor.colorAttachments[1].texture = gNormalTexture
        passDescriptor.colorAttachments[1].loadAction = .clear
        passDescriptor.colorAttachments[1].storeAction = .store
        
        passDescriptor.colorAttachments[2].texture = gPositionTexture
        passDescriptor.colorAttachments[2].loadAction = .clear
        passDescriptor.colorAttachments[2].storeAction = .store
        
        passDescriptor.colorAttachments[3].texture = lightingTexture
        passDescriptor.colorAttachments[3].loadAction = .clear
        passDescriptor.colorAttachments[3].storeAction = .store
        
        passDescriptor.depthAttachment.texture = gDepthTexture
        passDescriptor.depthAttachment.loadAction = .clear
        passDescriptor.depthAttachment.storeAction = .store
        passDescriptor.depthAttachment.clearDepth = 1.0
    }
    
    func doPass(with commandBuffer: MTLCommandBuffer?, _ closure: (MTLCommandEncoder)->Void)
    {
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: passDescriptor)
        
        renderEncoder?.label = "GBuffer Render Command Encoder"

        renderEncoder?.pushDebugGroup("Fill GBuffer Pass")
        
        renderEncoder?.setDepthStencilState(DepthStencilStateLibrary[.gbuffer])
        renderEncoder?.setStencilReferenceValue(128)
        
        renderEncoder?.setFrontFacing(.clockwise)
        renderEncoder?.setCullMode(.back)
        
        renderEncoder?.setRenderPipelineState(bspPipelineState)
        
        closure(renderEncoder!)
        
        renderEncoder?.popDebugGroup()
        
        renderEncoder?.endEncoding()
    }
    
    private func setupAlbedo()
    {
        let albedoTextureDecriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                              width: width,
                                                                              height: height,
                                                                              mipmapped: false)
        
        albedoTextureDecriptor.sampleCount = 1
        albedoTextureDecriptor.storageMode = .private
        albedoTextureDecriptor.usage = [.renderTarget, .shaderRead]
        
        gAlbedoTexture = Engine.device.makeTexture(descriptor: albedoTextureDecriptor)!
        gAlbedoTexture.label = "Albedo"
    }
    
    private func setupNormal()
    {
        let normalTextureDecriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float,
                                                                              width: width,
                                                                              height: height,
                                                                              mipmapped: false)
        
        normalTextureDecriptor.sampleCount = 1
        normalTextureDecriptor.storageMode = .private
        normalTextureDecriptor.usage = [.renderTarget, .shaderRead]
        
        gNormalTexture = Engine.device.makeTexture(descriptor: normalTextureDecriptor)!
        gNormalTexture.label = "Normals"
    }
    
    private func setupPosition()
    {
        let positionTextureDecriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float,
                                                                                width: width,
                                                                                height: height,
                                                                                mipmapped: false)
        
        positionTextureDecriptor.sampleCount = 1
        positionTextureDecriptor.storageMode = .private
        positionTextureDecriptor.usage = [.renderTarget, .shaderRead]
        
        gPositionTexture = Engine.device.makeTexture(descriptor: positionTextureDecriptor)!
        gPositionTexture.label = "Position"
    }
    
    private func setupDepth()
    {
        let depthTextureDecriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Preferences.depthStencilPixelFormat,
                                                                             width: width,
                                                                             height: height,
                                                                             mipmapped: false)
        
        depthTextureDecriptor.usage = [.renderTarget, .shaderRead]
        depthTextureDecriptor.storageMode = .private
        gDepthTexture = Engine.device.makeTexture(descriptor: depthTextureDecriptor)!
    }
    
    private func setupLighting()
    {
        let lightingTextureDecriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float,
                                                                                width: width,
                                                                                height: height,
                                                                                mipmapped: false)
        
        lightingTextureDecriptor.sampleCount = 1
        lightingTextureDecriptor.storageMode = .private
        lightingTextureDecriptor.usage = [.renderTarget, .shaderRead]
        
        lightingTexture = Engine.device.makeTexture(descriptor: lightingTextureDecriptor)!
        lightingTexture.label = "Lighting"
    }
    
    private func createBspPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
        descriptor.colorAttachments[1].pixelFormat = .rgba16Float
        descriptor.colorAttachments[2].pixelFormat = .rgba16Float
        descriptor.colorAttachments[3].pixelFormat = .rgba16Float
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "gbuffer_vertex_shader")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "gbuffer_fragment_shader")
        descriptor.vertexDescriptor = BSPMesh.vertexDescriptor()

        descriptor.label = "BSP Geometry Pipeline State"

        bspPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
}
