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
    
    private var _baseRenderPass: MTLRenderPassDescriptor!
    private var _ssaoRenderPass: MTLRenderPassDescriptor!
//    private var _finalRenderPass: MTLRenderPassDescriptor!
    
    private var _baseRenderPipelineState: MTLRenderPipelineState!
//    private var _ssaoRenderPipelineState: MTLRenderPipelineState!
    
    private let scene = ForestScene()
    
    private (set) var albedoMap: MTLTexture!
    private (set) var normalMap: MTLTexture!
    private (set) var positionMap: MTLTexture!
    private (set) var depthMap: MTLTexture!
    
    private (set) var ssaoTexture: MTLTexture!
    
    private let _finalQuad = SimpleQuad()
    
    init(view: MTKView)
    {
        super.init()
        
        mtkView(view, drawableSizeWillChange: view.drawableSize)
//        updateScreenSize(view.drawableSize)
        
//        createBaseRenderPass()
        createBaseRenderPipelineState()
        
        createSSAORenderPass()
        
//        _finalRenderPass = view.currentRenderPassDescriptor
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
    
    private func createBaseRenderPass()
    {
        let width = Int(Renderer.screenSize.x)
        let height = Int(Renderer.screenSize.y)
        
        // ------ BASE COLOR 0 TEXTURE ------
        let baseTextureDecriptor_0 = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                              width: width,
                                                                              height: height,
                                                                              mipmapped: false)
        
        baseTextureDecriptor_0.sampleCount = 1
        baseTextureDecriptor_0.storageMode = .private
        baseTextureDecriptor_0.usage = [.renderTarget, .shaderRead]
        
        albedoMap = Engine.device.makeTexture(descriptor: baseTextureDecriptor_0)!
        
        // ------ BASE COLOR 1 TEXTURE ------
        let baseTextureDecriptor_1 = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float,
                                                                              width: width,
                                                                              height: height,
                                                                              mipmapped: false)
        
        baseTextureDecriptor_1.sampleCount = 1
        baseTextureDecriptor_1.storageMode = .private
        baseTextureDecriptor_1.usage = [.renderTarget, .shaderRead]
        
        normalMap = Engine.device.makeTexture(descriptor: baseTextureDecriptor_1)!
        
        // ------ BASE COLOR 2 TEXTURE ------
        let baseTextureDecriptor_2 = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float,
                                                                              width: width,
                                                                              height: height,
                                                                              mipmapped: false)
        
        baseTextureDecriptor_2.sampleCount = 1
        baseTextureDecriptor_2.storageMode = .private
        baseTextureDecriptor_2.usage = [.renderTarget, .shaderRead]
        
        positionMap = Engine.device.makeTexture(descriptor: baseTextureDecriptor_2)!
        
        
        // ------ DEPTH TEXTURE ------
        let depthTextureDecriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Preferences.depthStencilPixelFormat,
                                                                             width: width,
                                                                             height: height,
                                                                             mipmapped: false)
        
        depthTextureDecriptor.usage = [.renderTarget, .shaderRead]
        depthTextureDecriptor.storageMode = .private
        depthMap = Engine.device.makeTexture(descriptor: depthTextureDecriptor)!
        
        _baseRenderPass = MTLRenderPassDescriptor()
        
        _baseRenderPass.colorAttachments[0].texture = albedoMap
        _baseRenderPass.colorAttachments[0].storeAction = .store
        _baseRenderPass.colorAttachments[0].loadAction = .clear
        
        _baseRenderPass.colorAttachments[1].texture = normalMap
        _baseRenderPass.colorAttachments[1].storeAction = .store
        _baseRenderPass.colorAttachments[1].loadAction = .clear
        
        _baseRenderPass.colorAttachments[2].texture = positionMap
        _baseRenderPass.colorAttachments[2].storeAction = .store
        _baseRenderPass.colorAttachments[2].loadAction = .clear
        
        _baseRenderPass.depthAttachment.texture = depthMap
        _baseRenderPass.depthAttachment.storeAction = .store
        _baseRenderPass.depthAttachment.loadAction = .clear
    }
    
    private func createSSAORenderPass()
    {
        let width = Int(Renderer.screenSize.x)
        let height = Int(Renderer.screenSize.y)
        
        let aoTextureDecriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r8Unorm,
                                                                              width: width,
                                                                              height: height,
                                                                              mipmapped: false)
        
        aoTextureDecriptor.sampleCount = 1
        aoTextureDecriptor.storageMode = .private
        aoTextureDecriptor.usage = [.renderTarget, .shaderRead]
        
        ssaoTexture = Engine.device.makeTexture(descriptor: aoTextureDecriptor)!
        
        _ssaoRenderPass = MTLRenderPassDescriptor()
        
        _ssaoRenderPass.colorAttachments[0].texture = ssaoTexture
        _ssaoRenderPass.colorAttachments[0].storeAction = .store
        _ssaoRenderPass.colorAttachments[0].loadAction = .clear
    }
    
    private func createBaseRenderPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
        descriptor.colorAttachments[1].pixelFormat = .rgba16Float
        descriptor.colorAttachments[2].pixelFormat = .rgba16Float
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = ShaderLibrary.vertex(.basic)
        descriptor.fragmentFunction = ShaderLibrary.fragment(.basic)
        descriptor.vertexDescriptor = VertexDescriptorLibrary.descriptor(.basic)

        descriptor.label = "Basic Render"

        _baseRenderPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func baseRenderPass(with commandBuffer: MTLCommandBuffer?)
    {
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: _baseRenderPass)
        
        renderEncoder?.label = "Base Render Command Encoder"

        renderEncoder?.pushDebugGroup("Starting Base Render")
        
        renderEncoder?.setRenderPipelineState(_baseRenderPipelineState)
        scene.render(with: renderEncoder)
        
        renderEncoder?.popDebugGroup()
        
        renderEncoder?.endEncoding()
    }
    
//    private func ssaoRenderPass(with commandBuffer: MTLCommandBuffer?, in view: MTKView)
//    {
//        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: _ssaoRenderPass)
//        
//        renderEncoder?.label = "SSAO Render Command Encoder"
//
//        renderEncoder?.pushDebugGroup("Starting SSAO Render")
//        
//        renderEncoder?.setRenderPipelineState(RenderPipelineStateLibrary[.ssao])
//        
//        renderEncoder?.setFragmentTexture(normalMap, index: 0)
//        renderEncoder?.setFragmentTexture(positionMap, index: 1)
//        renderEncoder?.setFragmentTexture(_finalQuad.kernelTexture, index: 2)
//        renderEncoder?.setFragmentTexture(_finalQuad.noiseTexture, index: 3)
//        
//        _finalQuad.drawPrimitives(with: renderEncoder)
//        
//        renderEncoder?.popDebugGroup()
//        
//        renderEncoder?.endEncoding()
//    }
    
    private func finalRenderPass(with commandBuffer: MTLCommandBuffer?, in view: MTKView)
    {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        renderEncoder?.label = "Final Render Command Encoder"

        renderEncoder?.pushDebugGroup("Starting Final Render")
        
        renderEncoder?.setRenderPipelineState(RenderPipelineStateLibrary[.final])
        
        renderEncoder?.setFragmentTexture(albedoMap, index: 0)
        renderEncoder?.setFragmentTexture(normalMap, index: 1)
        renderEncoder?.setFragmentTexture(positionMap, index: 2)
        renderEncoder?.setFragmentTexture(depthMap, index: 3)
        
        _finalQuad.drawPrimitives(with: renderEncoder)
        
        renderEncoder?.popDebugGroup()
        
        renderEncoder?.endEncoding()
    }
}

extension Renderer: MTKViewDelegate
{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize)
    {
        updateScreenSize(size)
        
        createBaseRenderPass()
    }
    
    func draw(in view: MTKView)
    {
        update(in: view)

        guard let drawable = view.currentDrawable else { return }

        let commandBuffer = Engine.commandQueue.makeCommandBuffer()
        commandBuffer?.label = "Base Command Buffer"

        baseRenderPass(with: commandBuffer)
//        ssaoRenderPass(with: commandBuffer, in: view)
        finalRenderPass(with: commandBuffer, in: view)

        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
