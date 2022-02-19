//
//  DeferredRenderer.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

class DeferredRenderer: NSObject
{
    static private (set) var screenSize: float2 = .zero
    
    static var aspectRatio: Float {
        guard screenSize.y > 0 else { return 1 }
        return screenSize.x / screenSize.y
    }
    
    private var _defaultLibrary: MTLLibrary!
    
    private var _shadowRenderPass: MTLRenderPassDescriptor!
    private var _gbufferRenderPass: MTLRenderPassDescriptor!
    private var _lightingRenderPass: MTLRenderPassDescriptor!
    
    private var _shadowPipelineState: MTLRenderPipelineState!
    private var _gbufferPipelineState: MTLRenderPipelineState!
    private var _lightingPipelineState: MTLRenderPipelineState!
    private var _compositePipelineState: MTLRenderPipelineState!
    private var _skyPipelineState: MTLRenderPipelineState!
    private var _simplePipelineState: MTLRenderPipelineState!
    
    private let scene = Q3MapScene()
    
    private var isShadowMapNeedsUpdate = true
    private var shadowTexture: MTLTexture!
    
    private var gAlbedoTexture: MTLTexture!
    private var gNormalTexture: MTLTexture!
    private var gPositionTexture: MTLTexture!
    private var gDepthTexture: MTLTexture!
    private var lightingTexture: MTLTexture!
    
    private var skyCubeTexture: MTLTexture!
    private let _skybox = Skybox()
    
    private let _fullscreenQuad = SimpleQuad()
    
    private var frameNum: UInt = 0
    private var preferredFramesPerSecond: Float = 60
    
    init(view: MTKView)
    {
        super.init()
        
        mtkView(view, drawableSizeWillChange: view.drawableSize)
        
        _defaultLibrary = Engine.device.makeDefaultLibrary()
        
        skyCubeTexture = TextureManager.shared.loadCubeTexture(imageName: "night-sky")

        createShadowPipelineState()
        createGBufferPipelineState()
        createLightingPipelineState()
        createCompositePipelineState()
        createSkyPipelineState()
        createSimplePipelineState()
        
        preferredFramesPerSecond = Float(view.preferredFramesPerSecond)
    }
    
    private func updateScreenSize(_ size: CGSize)
    {
        DeferredRenderer.screenSize.x = Float(size.width)
        DeferredRenderer.screenSize.y = Float(size.height)
    }
    
    fileprivate func update()
    {
        let dt = 1.0 / preferredFramesPerSecond
        GameTime.update(deltaTime: dt)
        
        scene.update()
    }
    
    // MARK: - PASSES
    
    private func createShadowPass()
    {
        let size: Int = 512
        
        let shadowTextureDescriptor = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .depth16Unorm,
                                                                                 size: size,
                                                                                 mipmapped: false)
        
        shadowTextureDescriptor.usage = [.renderTarget, .shaderRead]
        shadowTextureDescriptor.storageMode = .private
        
        shadowTexture = Engine.device.makeTexture(descriptor: shadowTextureDescriptor)!
        shadowTexture.label = "Shadow"

        _shadowRenderPass = MTLRenderPassDescriptor()
        _shadowRenderPass.depthAttachment.texture = shadowTexture
        _shadowRenderPass.depthAttachment.loadAction = .clear
        _shadowRenderPass.depthAttachment.storeAction = .store
        _shadowRenderPass.depthAttachment.clearDepth = 1.0
        _shadowRenderPass.renderTargetArrayLength = 6
    }
    
    private func createGBufferPass()
    {
        let width = Int(DeferredRenderer.screenSize.x)
        let height = Int(DeferredRenderer.screenSize.y)
        
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
        
        // ------ LIGHTING TEXTURE ------
        
        let lightingTextureDecriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float,
                                                                                width: width,
                                                                                height: height,
                                                                                mipmapped: false)
        
        lightingTextureDecriptor.sampleCount = 1
        lightingTextureDecriptor.storageMode = .private
        lightingTextureDecriptor.usage = [.renderTarget, .shaderRead]
        
        lightingTexture = Engine.device.makeTexture(descriptor: lightingTextureDecriptor)!
        lightingTexture.label = "Lighting"

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
        
        _gbufferRenderPass.colorAttachments[3].texture = lightingTexture
        _gbufferRenderPass.colorAttachments[3].loadAction = .clear
        _gbufferRenderPass.colorAttachments[3].storeAction = .store
        
        _gbufferRenderPass.depthAttachment.texture = gDepthTexture
        _gbufferRenderPass.depthAttachment.loadAction = .clear
        _gbufferRenderPass.depthAttachment.storeAction = .store
        _gbufferRenderPass.depthAttachment.clearDepth = 1.0
    }
    
    private func createLightingPass()
    {
        _lightingRenderPass = MTLRenderPassDescriptor()
        
        _lightingRenderPass.colorAttachments[0].texture = lightingTexture
        _lightingRenderPass.colorAttachments[0].loadAction = .clear
        _lightingRenderPass.colorAttachments[0].storeAction = .store
        
        _lightingRenderPass.depthAttachment.texture = gDepthTexture
        _lightingRenderPass.depthAttachment.loadAction = .load
        _lightingRenderPass.depthAttachment.storeAction = .dontCare
    }
    
    // MARK: - STATES
    
    private func createShadowPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.depthAttachmentPixelFormat = .depth16Unorm

        descriptor.vertexFunction = _defaultLibrary.makeFunction(name: "shadowmap_vertex_shader")
        descriptor.fragmentFunction = _defaultLibrary.makeFunction(name: "shadowmap_fragment_shader")
        descriptor.vertexDescriptor = VertexDescriptorLibrary.descriptor(.basic)
        descriptor.inputPrimitiveTopology = .triangle

        descriptor.label = "Shadow Render Pipeline State"

        _shadowPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createGBufferPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
        descriptor.colorAttachments[1].pixelFormat = .rgba16Float
        descriptor.colorAttachments[2].pixelFormat = .rgba16Float
        descriptor.colorAttachments[3].pixelFormat = .rgba16Float
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = _defaultLibrary.makeFunction(name: "gbuffer_vertex_shader")
        descriptor.fragmentFunction = _defaultLibrary.makeFunction(name: "gbuffer_fragment_shader")
        descriptor.vertexDescriptor = BSPMesh.vertexDescriptor()

        descriptor.label = "GBuffer Render Pipeline State"

        _gbufferPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createLightingPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .rgba16Float
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = _defaultLibrary.makeFunction(name: "lighting_vertex_shader")
        descriptor.fragmentFunction = _defaultLibrary.makeFunction(name: "lighting_fragment_shader")
        descriptor.vertexDescriptor = VertexDescriptorLibrary.descriptor(.basic)

        descriptor.label = "Lighting Render Pipeline State"

        _lightingPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createCompositePipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = _defaultLibrary.makeFunction(name: "compose_vertex_shader")
        descriptor.fragmentFunction = _defaultLibrary.makeFunction(name: "compose_fragment_shader")

        descriptor.label = "Composite Render Pipeline State"

        _compositePipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createSkyPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = _defaultLibrary.makeFunction(name: "skybox_vertex_shader")
        descriptor.fragmentFunction = _defaultLibrary.makeFunction(name: "skybox_fragment_shader")
        descriptor.vertexDescriptor = _skybox.vertexDescriptor

        descriptor.label = "Skybox Pipeline State"

        _skyPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createSimplePipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = _defaultLibrary.makeFunction(name: "wireframe_vertex_shader")
        descriptor.fragmentFunction = _defaultLibrary.makeFunction(name: "wireframe_fragment_shader")

        descriptor.label = "Simple Render Pipeline State"

        _simplePipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    // MARK: - DO PASSES
    
    private func doShadowPass(with commandBuffer: MTLCommandBuffer?)
    {
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: _shadowRenderPass)
        
        renderEncoder?.label = "Shadow Render Command Encoder"

        renderEncoder?.pushDebugGroup("Shadow Render")
        
        renderEncoder?.setDepthStencilState(DepthStencilStateLibrary[.shadow])
        
        renderEncoder?.setCullMode(.front)
        
        renderEncoder?.setRenderPipelineState(_shadowPipelineState)
        scene.renderShadows(with: renderEncoder)
        
        renderEncoder?.popDebugGroup()
        
        renderEncoder?.endEncoding()
    }
    
    private func doGeometryPass(with commandBuffer: MTLCommandBuffer?)
    {
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: _gbufferRenderPass)
        
        renderEncoder?.label = "GBuffer Render Command Encoder"

        renderEncoder?.pushDebugGroup("GBuffer Render")
        
        renderEncoder?.setDepthStencilState(DepthStencilStateLibrary[.gbuffer])
        renderEncoder?.setStencilReferenceValue(128)
        
        renderEncoder?.setFrontFacing(.clockwise)
        renderEncoder?.setCullMode(.back)
        
        renderEncoder?.setRenderPipelineState(_gbufferPipelineState)
        scene.render(with: renderEncoder, useMaterials: true)
        
        renderEncoder?.popDebugGroup()
        
        renderEncoder?.endEncoding()
    }
    
    private func doLightingPass(with commandBuffer: MTLCommandBuffer?)
    {
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: _lightingRenderPass)
        
        renderEncoder?.label = "Lighting Render Command Encoder"

        renderEncoder?.pushDebugGroup("Lighting Render")
        
        renderEncoder?.setDepthStencilState(DepthStencilStateLibrary[.lighting])
        
        renderEncoder?.setFrontFacing(.clockwise)
        renderEncoder?.setCullMode(.front)
        
        renderEncoder?.setRenderPipelineState(_lightingPipelineState)
        
        renderEncoder?.setFragmentTexture(gNormalTexture, index: 1)
        renderEncoder?.setFragmentTexture(gPositionTexture, index: 2)
        renderEncoder?.setFragmentTexture(shadowTexture, index: 3)
        
        scene.renderLightVolumes(with: renderEncoder)
        
        renderEncoder?.popDebugGroup()
        
        renderEncoder?.endEncoding()
    }
    
    private func doCompositePass(with commandBuffer: MTLCommandBuffer?, in view: MTKView)
    {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        renderPassDescriptor.depthAttachment.texture = gDepthTexture
        renderPassDescriptor.depthAttachment.storeAction = .dontCare
        renderPassDescriptor.depthAttachment.loadAction = .load
        
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        // COMPOSITE

        renderEncoder?.label = "Composite Render Command Encoder"

        renderEncoder?.pushDebugGroup("Composite Render")

        renderEncoder?.setDepthStencilState(DepthStencilStateLibrary[.compose])
        renderEncoder?.setStencilReferenceValue(128)

        renderEncoder?.setRenderPipelineState(_compositePipelineState)

//        var lightData: LightData = scene.lights.first?.lightData
//        renderEncoder?.setFragmentBytes(&lightData, length: LightData.stride, index: 0)
        
        var invCamPj = CameraManager.shared.mainCamera.projectionMatrix.inverse
        renderEncoder?.setFragmentBytes(&invCamPj, length: MemoryLayout<matrix_float4x4>.stride, index: 1)
        
        var viewMatrix = CameraManager.shared.mainCamera.viewMatrix
        renderEncoder?.setFragmentBytes(&viewMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 2)

        renderEncoder?.setFragmentTexture(gAlbedoTexture, index: 0)
        renderEncoder?.setFragmentTexture(gNormalTexture, index: 1)
        renderEncoder?.setFragmentTexture(gDepthTexture, index: 2)
        renderEncoder?.setFragmentTexture(lightingTexture, index: 3)
        renderEncoder?.setFragmentTexture(gPositionTexture, index: 4)

        _fullscreenQuad.drawPrimitives(with: renderEncoder)

        renderEncoder?.popDebugGroup()
        
        // SKY

        renderEncoder?.pushDebugGroup("Sky Render")

        renderEncoder?.setDepthStencilState(DepthStencilStateLibrary[.sky])
        renderEncoder?.setRenderPipelineState(_skyPipelineState)

        var sceneConstants = scene.sceneConstants
        renderEncoder?.setVertexBytes(&sceneConstants, length: SceneConstants.stride, index: 1)

        renderEncoder?.setFragmentTexture(skyCubeTexture, index: 1)

        _skybox.render(with: renderEncoder!)

        renderEncoder?.popDebugGroup()
        
        
//        // DEBUG
//
//        renderEncoder?.pushDebugGroup("Bounding Boxes")
//
//        renderEncoder?.setDepthStencilState(DepthStencilStateLibrary[.less])
//        renderEncoder?.setRenderPipelineState(_simplePipelineState)
//
//        scene.renderBoundingBoxes(with: renderEncoder)
//
//        renderEncoder?.popDebugGroup()
        
        
        renderEncoder?.endEncoding()
    }
    
    private func render(in view: MTKView)
    {
        guard let drawable = view.currentDrawable else { return }
        
//        // ========= SHADOW =======================================
//
//        if isShadowMapNeedsUpdate
//        {
//            let shadowCommandBuffer = Engine.commandQueue.makeCommandBuffer()
//            shadowCommandBuffer?.label = "Shadow Command Buffer"
//
//            doShadowPass(with: shadowCommandBuffer)
//
//            shadowCommandBuffer?.commit()
//
//            isShadowMapNeedsUpdate = false
//        }

        // ========= G-BUFFER =======================================

        let geometryCommandBuffer = Engine.commandQueue.makeCommandBuffer()
        geometryCommandBuffer?.label = "Geometry Command Buffer"

        doGeometryPass(with: geometryCommandBuffer)

        geometryCommandBuffer?.commit()

//        // ========= LIGHTING =======================================
//
//        let lightingCommandBuffer = Engine.commandQueue.makeCommandBuffer()
//        lightingCommandBuffer?.label = "Lighting Command Buffer"
//
//        doLightingPass(with: lightingCommandBuffer)
//
//        lightingCommandBuffer?.commit()
        
        // ========= COMPOSITE =======================================
        
        let compositeCommandBuffer = Engine.commandQueue.makeCommandBuffer()
        compositeCommandBuffer?.label = "Composite Command Buffer"
        
        doCompositePass(with: compositeCommandBuffer, in: view)
        
        // =======================================================

        compositeCommandBuffer?.present(drawable)
        
        compositeCommandBuffer?.commit()
    }
}

extension DeferredRenderer: MTKViewDelegate
{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize)
    {
        updateScreenSize(size)
        
        createShadowPass()
        createGBufferPass()
        createLightingPass()
    }
    
    func draw(in view: MTKView)
    {
        update()
        render(in: view)
    }
}
