//
//  Renderer.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

class Renderer: NSObject
{
    static private (set) var screenSize: float2 = .zero
    
    static var aspectRatio: Float {
        guard screenSize.y > 0 else { return 1 }
        return screenSize.x / screenSize.y
    }
    
    private var _skyRenderPass: MTLRenderPassDescriptor!
    private var _baseRenderPass: MTLRenderPassDescriptor!
    private var _ssaoRenderPass: MTLRenderPassDescriptor!
    
    private var _baseRenderPipelineState: MTLRenderPipelineState!
    private var _finalRenderPipelineState: MTLRenderPipelineState!
    private var _skyRenderPipelineState: MTLRenderPipelineState!
    
    private let scene = ForestScene()
    
    private (set) var gAlbedoTexture: MTLTexture!
    private (set) var gNormalTexture: MTLTexture!
    private (set) var gPositionTexture: MTLTexture!
    private (set) var gDepthMTexture: MTLTexture!
    
    private let _skysphere = SkySphere()
    private let _finalQuad = SimpleQuad()
    
    init(view: MTKView)
    {
        super.init()
        
        mtkView(view, drawableSizeWillChange: view.drawableSize)

        createBaseRenderPipelineState()
        createFinalRenderPipelineState()
        createSkyRenderPipelineState()
    }
    
    private func updateScreenSize(_ size: CGSize)
    {
        Renderer.screenSize.x = Float(size.width)
        Renderer.screenSize.y = Float(size.height)
    }
    
    fileprivate func update(in view: MTKView)
    {
        let dt = 1.0 / Float(view.preferredFramesPerSecond)
        GameTime.update(deltaTime: dt)
        
        scene.update()
    }
    
    private func createGBufferPass()
    {
        let width = Int(Renderer.screenSize.x)
        let height = Int(Renderer.screenSize.y)
        
        // ------ ALBEDO ------
        let albedoTextureDecriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                              width: width,
                                                                              height: height,
                                                                              mipmapped: false)
        
        albedoTextureDecriptor.sampleCount = 1
        albedoTextureDecriptor.storageMode = .private
        albedoTextureDecriptor.usage = [.renderTarget, .shaderRead]
        
        gAlbedoTexture = Engine.device.makeTexture(descriptor: albedoTextureDecriptor)!
        
        // ------ NORMAL ------
        let normalTextureDecriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float,
                                                                              width: width,
                                                                              height: height,
                                                                              mipmapped: false)
        
        normalTextureDecriptor.sampleCount = 1
        normalTextureDecriptor.storageMode = .private
        normalTextureDecriptor.usage = [.renderTarget, .shaderRead]
        
        gNormalTexture = Engine.device.makeTexture(descriptor: normalTextureDecriptor)!
        
        // ------ POSITION ------
        let positionTextureDecriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float,
                                                                                width: width,
                                                                                height: height,
                                                                                mipmapped: false)
        
        positionTextureDecriptor.sampleCount = 1
        positionTextureDecriptor.storageMode = .private
        positionTextureDecriptor.usage = [.renderTarget, .shaderRead]
        
        gPositionTexture = Engine.device.makeTexture(descriptor: positionTextureDecriptor)!
        
        
        // ------ DEPTH TEXTURE ------
        let depthTextureDecriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Preferences.depthStencilPixelFormat,
                                                                             width: width,
                                                                             height: height,
                                                                             mipmapped: false)
        
        depthTextureDecriptor.usage = [.renderTarget, .shaderRead]
        depthTextureDecriptor.storageMode = .private
        gDepthMTexture = Engine.device.makeTexture(descriptor: depthTextureDecriptor)!
        
        _baseRenderPass = MTLRenderPassDescriptor()
        
        _baseRenderPass.colorAttachments[0].texture = gAlbedoTexture
        _baseRenderPass.colorAttachments[0].storeAction = .store
        _baseRenderPass.colorAttachments[0].loadAction = .clear
        
        _baseRenderPass.colorAttachments[1].texture = gNormalTexture
        _baseRenderPass.colorAttachments[1].storeAction = .store
        _baseRenderPass.colorAttachments[1].loadAction = .clear
        
        _baseRenderPass.colorAttachments[2].texture = gPositionTexture
        _baseRenderPass.colorAttachments[2].storeAction = .store
        _baseRenderPass.colorAttachments[2].loadAction = .clear
        
        _baseRenderPass.depthAttachment.texture = gDepthMTexture
        _baseRenderPass.depthAttachment.storeAction = .store
        _baseRenderPass.depthAttachment.loadAction = .clear
        
        _baseRenderPass.stencilAttachment.texture = gDepthMTexture
        _baseRenderPass.stencilAttachment.storeAction = .store
        _baseRenderPass.stencilAttachment.loadAction = .clear
    }
    
    private func createBaseRenderPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
        descriptor.colorAttachments[1].pixelFormat = .rgba16Float
        descriptor.colorAttachments[2].pixelFormat = .rgba16Float
        
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat
        descriptor.stencilAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = ShaderLibrary.vertex(.basic)
        descriptor.fragmentFunction = ShaderLibrary.fragment(.basic)
        descriptor.vertexDescriptor = VertexDescriptorLibrary.descriptor(.basic)

        descriptor.label = "GBuffer Render"

        _baseRenderPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createFinalRenderPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat
        descriptor.stencilAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = ShaderLibrary.vertex(.final)
        descriptor.fragmentFunction = ShaderLibrary.fragment(.final)

        descriptor.label = "Composite Render"

        _finalRenderPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createSkyRenderPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat
        descriptor.stencilAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = ShaderLibrary.vertex(.skysphere)
        descriptor.fragmentFunction = ShaderLibrary.fragment(.skysphere)
        descriptor.vertexDescriptor = VertexDescriptorLibrary.descriptor(.basic)

        descriptor.label = "Skysphere Render"

        _skyRenderPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func gBufferPass(with commandBuffer: MTLCommandBuffer?)
    {
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: _baseRenderPass)
        
        renderEncoder?.label = "GBuffer Render Command Encoder"

        renderEncoder?.pushDebugGroup("Starting GBuffer Render")
        
        renderEncoder?.setDepthStencilState(DepthStencilStateLibrary[.gbuffer])
        renderEncoder?.setStencilReferenceValue(128)
        
        renderEncoder?.setRenderPipelineState(_baseRenderPipelineState)
        scene.render(with: renderEncoder)
        
        renderEncoder?.popDebugGroup()
        
        renderEncoder?.endEncoding()
    }
    
    private func compositePass(with commandBuffer: MTLCommandBuffer?, in view: MTKView)
    {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        renderPassDescriptor.depthAttachment.texture = gDepthMTexture
        renderPassDescriptor.depthAttachment.storeAction = .dontCare
        renderPassDescriptor.depthAttachment.loadAction = .load
        
        renderPassDescriptor.stencilAttachment.texture = gDepthMTexture
        renderPassDescriptor.stencilAttachment.storeAction = .dontCare
        renderPassDescriptor.stencilAttachment.loadAction = .load
        
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        // COMPOSITE
        
        renderEncoder?.label = "Composite Render Command Encoder"

        renderEncoder?.pushDebugGroup("Starting Composite Render")
        
        renderEncoder?.setDepthStencilState(DepthStencilStateLibrary[.compose])
        renderEncoder?.setStencilReferenceValue(128)
        
        renderEncoder?.setRenderPipelineState(_finalRenderPipelineState)
        
        renderEncoder?.setFragmentTexture(gAlbedoTexture, index: 0)
        renderEncoder?.setFragmentTexture(gNormalTexture, index: 1)
        renderEncoder?.setFragmentTexture(gPositionTexture, index: 2)
        renderEncoder?.setFragmentTexture(gDepthMTexture, index: 3)
        
        _finalQuad.drawPrimitives(with: renderEncoder)
        
        renderEncoder?.popDebugGroup()
        
        // SKY
        
        renderEncoder?.pushDebugGroup("Starting Sky Render")
        
        renderEncoder?.setDepthStencilState(DepthStencilStateLibrary[.sky])
        renderEncoder?.setRenderPipelineState(_skyRenderPipelineState)
        
        var sceneConstants = scene.sceneConstants
        renderEncoder?.setVertexBytes(&sceneConstants, length: SceneConstants.stride, index: 1)
        
        _skysphere.doRender(with: renderEncoder)
        
        renderEncoder?.popDebugGroup()
        
        renderEncoder?.endEncoding()
    }
}

extension Renderer: MTKViewDelegate
{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize)
    {
        updateScreenSize(size)
        
        createGBufferPass()
    }
    
    func draw(in view: MTKView)
    {
        update(in: view)

        guard let drawable = view.currentDrawable else { return }

        let commandBuffer = Engine.commandQueue.makeCommandBuffer()
        commandBuffer?.label = "Base Command Buffer"

        gBufferPass(with: commandBuffer)
        compositePass(with: commandBuffer, in: view)

        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
