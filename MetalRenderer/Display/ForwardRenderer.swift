//
//  ForwardRenderer.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.02.2022.
//

import MetalKit

class ForwardRenderer: NSObject
{
    static private (set) var screenSize: float2 = .zero
    
    static var aspectRatio: Float {
        guard screenSize.y > 0 else { return 1 }
        return screenSize.x / screenSize.y
    }
    
    private var _skyboxPipelineState: MTLRenderPipelineState!
    private var _worldMeshPipelineState: MTLRenderPipelineState!
    private var _staticMeshPipelineState: MTLRenderPipelineState!
    private var _skeletalMeshPipelineState: MTLRenderPipelineState!
    
    private var _skyCubeTexture: MTLTexture!
    private let _skybox = Skybox()
    
    private let scene = Q3MapScene()
    
    private var preferredFramesPerSecond: Float = 60
    
    init(view: MTKView)
    {
        super.init()
        
        mtkView(view, drawableSizeWillChange: view.drawableSize)
        
        _skyCubeTexture = TextureManager.shared.loadCubeTexture(imageName: "night-sky")
        
        createSkyboxPipelineState()
        createWorldMeshPipelineState()
        createStaticMeshPipelineState()
        createSkeletalMeshPipelineState()
        
        preferredFramesPerSecond = Float(view.preferredFramesPerSecond)
    }
    
    private func updateScreenSize(_ size: CGSize)
    {
        ForwardRenderer.screenSize.x = Float(size.width)
        ForwardRenderer.screenSize.y = Float(size.height)
    }
    
    fileprivate func update()
    {
        let dt = 1.0 / preferredFramesPerSecond
        GameTime.update(deltaTime: dt)
        
        scene.update()
    }
    
    // MARK: - STATES
    
    private func createSkyboxPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "skybox_vertex_shader")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "skybox_fragment_shader")
        descriptor.vertexDescriptor = _skybox.vertexDescriptor

        descriptor.label = "Skybox Pipeline State"

        _skyboxPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createWorldMeshPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "world_mesh_vs")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "world_mesh_fs")
        descriptor.vertexDescriptor = BSPMesh.vertexDescriptor()

        descriptor.label = "World Mesh Pipeline State"

        _worldMeshPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createStaticMeshPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "static_mesh_vs")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "static_mesh_fs")
        descriptor.vertexDescriptor = StaticMesh.vertexDescriptor()

        descriptor.label = "Static Mesh Pipeline State"

        _staticMeshPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
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

        _skeletalMeshPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    // MARK: - DO PASSES
    
    private func doMainRenderPass(with commandBuffer: MTLCommandBuffer?, in view: MTKView)
    {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        renderEncoder?.label = "Main Pass Command Encoder"
        
        // SKYBOX

        renderEncoder?.pushDebugGroup("Skybox Render")

        renderEncoder?.setDepthStencilState(DepthStencilStateLibrary[.sky])
        renderEncoder?.setRenderPipelineState(_skyboxPipelineState)

        var sceneConstants = scene.sceneConstants
        renderEncoder?.setVertexBytes(&sceneConstants, length: SceneConstants.stride, index: 1)

        renderEncoder?.setFragmentTexture(_skyCubeTexture, index: 1)

        _skybox.render(with: renderEncoder!)

        renderEncoder?.popDebugGroup()
        
        // WORLD MESH

        renderEncoder?.pushDebugGroup("World Mesh Render")

            renderEncoder?.setDepthStencilState(DepthStencilStateLibrary[.less])

            renderEncoder?.setFrontFacing(.clockwise)
            renderEncoder?.setCullMode(.back)

            renderEncoder?.setRenderPipelineState(_worldMeshPipelineState)
            scene.renderWorld(with: renderEncoder)

        renderEncoder?.popDebugGroup()
        
        
        // STATIC MESHES

        renderEncoder?.pushDebugGroup("Static Meshes Render")

        renderEncoder?.setDepthStencilState(DepthStencilStateLibrary[.less])
        
    //        renderEncoder?.setFrontFacing(.clockwise)
    //        renderEncoder?.setCullMode(.back)
            
            renderEncoder?.setTriangleFillMode(.lines)
            
            renderEncoder?.setRenderPipelineState(_staticMeshPipelineState)
            scene.renderStaticMeshes(with: renderEncoder)

        renderEncoder?.popDebugGroup()
        
        // SKELETAL MESHES

        renderEncoder?.pushDebugGroup("Skeletal Meshes Render")

        renderEncoder?.setDepthStencilState(DepthStencilStateLibrary[.less])
        
//            renderEncoder?.setFrontFacing(.clockwise)
            renderEncoder?.setCullMode(.none)
            
    //        renderEncoder?.setTriangleFillMode(.lines)
            
            renderEncoder?.setRenderPipelineState(_skeletalMeshPipelineState)
            scene.renderSkeletalMeshes(with: renderEncoder)

        renderEncoder?.popDebugGroup()
        
        renderEncoder?.endEncoding()
    }
    
    private func render(in view: MTKView)
    {
        guard let drawable = view.currentDrawable else { return }
        

        let compositeCommandBuffer = Engine.commandQueue.makeCommandBuffer()
        compositeCommandBuffer?.label = "Main Pass Command Buffer"
        
        doMainRenderPass(with: compositeCommandBuffer, in: view)

        compositeCommandBuffer?.present(drawable)
        
        compositeCommandBuffer?.commit()
    }
}

extension ForwardRenderer: MTKViewDelegate
{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize)
    {
        updateScreenSize(size)
    }
    
    func draw(in view: MTKView)
    {
        update()
        render(in: view)
    }
}

