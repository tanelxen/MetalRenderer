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
    
    private var _gbufferRenderPass: MTLRenderPassDescriptor!
    
    private var _gbufferPipelineState: MTLRenderPipelineState!
    private var _compositePipelineState: MTLRenderPipelineState!
    private var _skyPipelineState: MTLRenderPipelineState!
    
    private let scene = ForestScene()
    
    private var gAlbedoTexture: MTLTexture!
    private var gNormalTexture: MTLTexture!
    private var gPositionTexture: MTLTexture!
    private var gDepthTexture: MTLTexture!
    
    private let _skysphere = SkySphere()
    private let _fullscreenQuad = SimpleQuad()
    
    private var preferredFramesPerSecond: Float = 60
    
    init(view: MTKView)
    {
        super.init()
        
        mtkView(view, drawableSizeWillChange: view.drawableSize)

        createGBufferPipelineState()
        createCompositePipelineState()
        createSkyPipelineState()
        
        preferredFramesPerSecond = Float(view.preferredFramesPerSecond)
    }
    
    private func updateScreenSize(_ size: CGSize)
    {
        Renderer.screenSize.x = Float(size.width)
        Renderer.screenSize.y = Float(size.height)
    }
    
    fileprivate func update()
    {
        let dt = 1.0 / preferredFramesPerSecond
        GameTime.update(deltaTime: dt)
        
        
//        let start = CFAbsoluteTimeGetCurrent()
        
        scene.update()
        
//        let diff = (CFAbsoluteTimeGetCurrent() - start) * 1000
//        print("Took \(diff) ms")
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
        gAlbedoTexture.label = "Albedo"
        
        // ------ NORMAL ------
        let normalTextureDecriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float,
                                                                              width: width,
                                                                              height: height,
                                                                              mipmapped: false)
        
        normalTextureDecriptor.sampleCount = 1
        normalTextureDecriptor.storageMode = .private
        normalTextureDecriptor.usage = [.renderTarget, .shaderRead]
        
        gNormalTexture = Engine.device.makeTexture(descriptor: normalTextureDecriptor)!
        gNormalTexture.label = "Normals"
        
        // ------ POSITION ------
        let positionTextureDecriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float,
                                                                                width: width,
                                                                                height: height,
                                                                                mipmapped: false)
        
        positionTextureDecriptor.sampleCount = 1
        positionTextureDecriptor.storageMode = .private
        positionTextureDecriptor.usage = [.renderTarget, .shaderRead]
        
        gPositionTexture = Engine.device.makeTexture(descriptor: positionTextureDecriptor)!
        gPositionTexture.label = "Position"
        
        // ------ DEPTH TEXTURE ------
        let depthTextureDecriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Preferences.depthStencilPixelFormat,
                                                                             width: width,
                                                                             height: height,
                                                                             mipmapped: false)
        
        depthTextureDecriptor.usage = [.renderTarget, .shaderRead]
        depthTextureDecriptor.storageMode = .private
        gDepthTexture = Engine.device.makeTexture(descriptor: depthTextureDecriptor)!

        _gbufferRenderPass = MTLRenderPassDescriptor()
        
        _gbufferRenderPass.colorAttachments[0].texture = gAlbedoTexture
        _gbufferRenderPass.colorAttachments[0].loadAction = .clear
        _gbufferRenderPass.colorAttachments[0].storeAction = .store
        
        _gbufferRenderPass.colorAttachments[1].texture = gNormalTexture
        _gbufferRenderPass.colorAttachments[1].loadAction = .clear
        _gbufferRenderPass.colorAttachments[1].storeAction = .store
        
        _gbufferRenderPass.colorAttachments[2].texture = gPositionTexture
        _gbufferRenderPass.colorAttachments[2].loadAction = .clear
        _gbufferRenderPass.colorAttachments[2].storeAction = .store
        
        _gbufferRenderPass.depthAttachment.texture = gDepthTexture
        _gbufferRenderPass.depthAttachment.loadAction = .clear
        _gbufferRenderPass.depthAttachment.storeAction = .store

        _gbufferRenderPass.stencilAttachment.texture = gDepthTexture
        _gbufferRenderPass.stencilAttachment.loadAction = .clear
        _gbufferRenderPass.stencilAttachment.storeAction = .store
    }
    
    private func createGBufferPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
        descriptor.colorAttachments[1].pixelFormat = .rgba16Float
        descriptor.colorAttachments[2].pixelFormat = .rgba16Float
        
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat
        descriptor.stencilAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = ShaderLibrary.vertex(.gbuffer)
        descriptor.fragmentFunction = ShaderLibrary.fragment(.gbuffer)
        descriptor.vertexDescriptor = VertexDescriptorLibrary.descriptor(.basic)

        descriptor.label = "GBuffer Render Pipeline State"

        _gbufferPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createCompositePipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat
        descriptor.stencilAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = ShaderLibrary.vertex(.compose)
        descriptor.fragmentFunction = ShaderLibrary.fragment(.compose)

        descriptor.label = "Composite Render Pipeline State"

        _compositePipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createSkyPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat
        descriptor.stencilAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = ShaderLibrary.vertex(.skysphere)
        descriptor.fragmentFunction = ShaderLibrary.fragment(.skysphere)
        descriptor.vertexDescriptor = VertexDescriptorLibrary.descriptor(.basic)

        descriptor.label = "Skysphere Render Pipeline State"

        _skyPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func gbufferPass(with commandBuffer: MTLCommandBuffer?)
    {
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: _gbufferRenderPass)
        
        renderEncoder?.label = "GBuffer Render Command Encoder"

        renderEncoder?.pushDebugGroup("GBuffer Render")
        
        renderEncoder?.setDepthStencilState(DepthStencilStateLibrary[.gbuffer])
        renderEncoder?.setStencilReferenceValue(128)
        
        renderEncoder?.setRenderPipelineState(_gbufferPipelineState)
        scene.render(with: renderEncoder, useMaterials: true)
        
        renderEncoder?.popDebugGroup()
        
        renderEncoder?.endEncoding()
    }
    
    private func compositePass(with commandBuffer: MTLCommandBuffer?, in view: MTKView)
    {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        renderPassDescriptor.depthAttachment.texture = gDepthTexture
        renderPassDescriptor.depthAttachment.storeAction = .dontCare
        renderPassDescriptor.depthAttachment.loadAction = .load
        
        renderPassDescriptor.stencilAttachment.texture = gDepthTexture
        renderPassDescriptor.stencilAttachment.storeAction = .dontCare
        renderPassDescriptor.stencilAttachment.loadAction = .load
        
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        // COMPOSITE
        
        renderEncoder?.label = "Composite Render Command Encoder"

        renderEncoder?.pushDebugGroup("Composite Render")
        
        renderEncoder?.setDepthStencilState(DepthStencilStateLibrary[.compose])
        renderEncoder?.setStencilReferenceValue(128)
        
        renderEncoder?.setRenderPipelineState(_compositePipelineState)
        
        renderEncoder?.setFragmentTexture(gAlbedoTexture, index: 0)
        renderEncoder?.setFragmentTexture(gNormalTexture, index: 1)
        renderEncoder?.setFragmentTexture(gPositionTexture, index: 2)
        renderEncoder?.setFragmentTexture(gDepthTexture, index: 3)
        
        
        // LIGHTS
        var lightDatas: [LightData] = scene.lights.map { $0.lightData }
        var lightCount = lightDatas.count
        
        renderEncoder?.setFragmentBytes(&lightDatas, length: LightData.stride * lightCount, index: 3)
        renderEncoder?.setFragmentBytes(&lightCount, length: Int32.size, index: 4)
        
        
        _fullscreenQuad.drawPrimitives(with: renderEncoder)
        
        renderEncoder?.popDebugGroup()
        
        // SKY
        
        renderEncoder?.pushDebugGroup("Sky Render")
        
        renderEncoder?.setDepthStencilState(DepthStencilStateLibrary[.sky])
        renderEncoder?.setRenderPipelineState(_skyPipelineState)
        
        var sceneConstants = scene.sceneConstants
        renderEncoder?.setVertexBytes(&sceneConstants, length: SceneConstants.stride, index: 1)
        
        _skysphere.doRender(with: renderEncoder, useMaterials: true)
        
        renderEncoder?.popDebugGroup()
        
        renderEncoder?.endEncoding()
    }
    
    private func render(in view: MTKView)
    {
        guard let drawable = view.currentDrawable else { return }

        // ========= G-BUFFER =======================================
        
        let geometryCommandBuffer = Engine.commandQueue.makeCommandBuffer()
        geometryCommandBuffer?.label = "Geometry Command Buffer"
        
        gbufferPass(with: geometryCommandBuffer)
        
        geometryCommandBuffer?.commit()
        
        // ========= COMPOSITE =======================================
        
        let compositeCommandBuffer = Engine.commandQueue.makeCommandBuffer()
        compositeCommandBuffer?.label = "Composite Command Buffer"
        
        compositePass(with: compositeCommandBuffer, in: view)

        compositeCommandBuffer?.present(drawable)
        
        compositeCommandBuffer?.commit()
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
        update()
        render(in: view)
    }
}
