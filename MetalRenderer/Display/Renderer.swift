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
//    private var _finalRenderPass: MTLRenderPassDescriptor!
    
    private let scene = ForestScene()
    
    private (set) var baseColorTexture_0: MTLTexture!
    private (set) var baseColorTexture_1: MTLTexture!
    private (set) var baseColorTexture_2: MTLTexture!
    private (set) var baseDepthTexture: MTLTexture!
    
    private let _finalQuad = SimpleQuad()
    
    init(view: MTKView)
    {
        super.init()
        
        updateScreenSize(view.drawableSize)
        
        createBaseRenderPass()
        
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
        let baseTextureDecriptor_0 = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Preferences.colorPixelFormat,
                                                                              width: width,
                                                                              height: height,
                                                                              mipmapped: false)
        
        baseTextureDecriptor_0.usage = [.renderTarget, .shaderRead]
        baseColorTexture_0 = Engine.device.makeTexture(descriptor: baseTextureDecriptor_0)!
        
        // ------ BASE COLOR 1 TEXTURE ------
        let baseTextureDecriptor_1 = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Preferences.colorPixelFormat,
                                                                              width: width,
                                                                              height: height,
                                                                              mipmapped: false)
        
        baseTextureDecriptor_1.usage = [.renderTarget, .shaderRead]
        baseColorTexture_1 = Engine.device.makeTexture(descriptor: baseTextureDecriptor_1)!
        
        // ------ BASE COLOR 2 TEXTURE ------
        let baseTextureDecriptor_2 = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Preferences.colorPixelFormat,
                                                                              width: width,
                                                                              height: height,
                                                                              mipmapped: false)
        
        baseTextureDecriptor_2.sampleCount = 1
        baseTextureDecriptor_2.storageMode = .private
        baseTextureDecriptor_2.textureType = .type2D
        baseTextureDecriptor_2.usage = [.renderTarget, .shaderRead]
        
        baseColorTexture_2 = Engine.device.makeTexture(descriptor: baseTextureDecriptor_2)!
        
        
        // ------ DEPTH TEXTURE ------
        let depthTextureDecriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Preferences.depthStencilPixelFormat,
                                                                             width: width,
                                                                             height: height,
                                                                             mipmapped: false)
        
        depthTextureDecriptor.usage = [.renderTarget, .shaderRead]
        depthTextureDecriptor.storageMode = .private
        baseDepthTexture = Engine.device.makeTexture(descriptor: depthTextureDecriptor)!
        
        _baseRenderPass = MTLRenderPassDescriptor()
        
        _baseRenderPass.colorAttachments[0].texture = baseColorTexture_0
        _baseRenderPass.colorAttachments[0].storeAction = .store
        _baseRenderPass.colorAttachments[0].loadAction = .clear
        
        _baseRenderPass.colorAttachments[1].texture = baseColorTexture_1
        _baseRenderPass.colorAttachments[1].storeAction = .store
        _baseRenderPass.colorAttachments[1].loadAction = .clear
        
//        _baseRenderPass.colorAttachments[2].texture = baseColorTexture_2
//        _baseRenderPass.colorAttachments[2].storeAction = .store
//        _baseRenderPass.colorAttachments[2].loadAction = .clear
        
        _baseRenderPass.depthAttachment.texture = baseDepthTexture
        _baseRenderPass.depthAttachment.storeAction = .store
        _baseRenderPass.depthAttachment.loadAction = .clear
    }
    
    private func baseRenderPass(with commandBuffer: MTLCommandBuffer?)
    {
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: _baseRenderPass)
        
        renderEncoder?.label = "Base Render Command Encoder"

        renderEncoder?.pushDebugGroup("Starting Base Render")
        scene.render(with: renderEncoder)
        renderEncoder?.popDebugGroup()
        
        renderEncoder?.endEncoding()
    }
    
    private func finalRenderPass(with commandBuffer: MTLCommandBuffer?, in view: MTKView)
    {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        renderEncoder?.label = "Final Render Command Encoder"

        renderEncoder?.pushDebugGroup("Starting Final Render")
        
        renderEncoder?.setRenderPipelineState(RenderPipelineStateLibrary[.final])
        renderEncoder?.setFragmentTexture(baseColorTexture_0, index: 0)
        
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
        finalRenderPass(with: commandBuffer, in: view)

        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
