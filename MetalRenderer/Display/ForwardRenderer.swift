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
    
    private var skyboxPipelineState: MTLRenderPipelineState!
    private var worldMeshPipelineState: MTLRenderPipelineState!
    private var staticMeshPipelineState: MTLRenderPipelineState!
    private var skeletalMeshPipelineState: MTLRenderPipelineState!
    private var solidColorPipelineState: MTLRenderPipelineState!
    
    private var regularStencilState: MTLDepthStencilState = {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.isDepthWriteEnabled = true
        descriptor.depthCompareFunction = .less
        descriptor.label = "Regular"
        return Engine.device.makeDepthStencilState(descriptor: descriptor)!
    }()
    
    private var skyStencilState: MTLDepthStencilState = {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.isDepthWriteEnabled = false
        descriptor.depthCompareFunction = .lessEqual
        descriptor.label = "Sky"
        return Engine.device.makeDepthStencilState(descriptor: descriptor)!
    }()
    
    private let scene = Q3MapScene()
    
    private var preferredFramesPerSecond: Float = 60
    
    init(view: MTKView)
    {
        super.init()
        
        mtkView(view, drawableSizeWillChange: view.drawableSize)
        
        createSkyboxPipelineState()
        createWorldMeshPipelineState()
        createStaticMeshPipelineState()
        createSkeletalMeshPipelineState()
        createSolidColorPipelineState()
        
        preferredFramesPerSecond = Float(view.preferredFramesPerSecond)
    }
    
    private func updateScreenSize(_ size: CGSize)
    {
        ForwardRenderer.screenSize.x = Float(size.width)
        ForwardRenderer.screenSize.y = Float(size.height)
        
        //TODO: переписать под сущность Viewport
        CameraManager.shared.mainCamera.updateViewport()
    }
    
    fileprivate func update()
    {
        GameTime.update()
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

        descriptor.label = "Skybox Pipeline State"

        skyboxPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
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

        worldMeshPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
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

        staticMeshPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
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

        skeletalMeshPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func createSolidColorPipelineState()
    {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.colorAttachments[0].pixelFormat = Preferences.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = Preferences.depthStencilPixelFormat

        descriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "solid_color_vs")
        descriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "solid_color_fs")

        descriptor.label = "Solid Color Render Pipeline State"

        solidColorPipelineState = try! Engine.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    // MARK: - DO PASSES
    
    private func doMainRenderPass(with commandBuffer: MTLCommandBuffer?, in view: MTKView)
    {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        renderEncoder?.label = "Main Pass Command Encoder"
        
        renderEncoder?.setFrontFacing(.counterClockwise)
        renderEncoder?.setCullMode(.back)
        
        // SKYBOX
        renderEncoder?.pushDebugGroup("Skybox Render")
            renderEncoder?.setDepthStencilState(skyStencilState)
            renderEncoder?.setRenderPipelineState(skyboxPipelineState)
            scene.renderSky(with: renderEncoder)
        renderEncoder?.popDebugGroup()
        
        renderEncoder?.setFrontFacing(.clockwise)
        renderEncoder?.setCullMode(.back)
        
        renderEncoder?.setDepthStencilState(regularStencilState)
        
        // WORLD MESH
        renderEncoder?.pushDebugGroup("World Mesh Render")
            renderEncoder?.setRenderPipelineState(worldMeshPipelineState)
            scene.renderWorld(with: renderEncoder)
        renderEncoder?.popDebugGroup()
        
        
        // STATIC MESHES
        renderEncoder?.pushDebugGroup("Static Meshes Render")
            renderEncoder?.setRenderPipelineState(staticMeshPipelineState)
            scene.renderStaticMeshes(with: renderEncoder)
        renderEncoder?.popDebugGroup()
        
        // SKELETAL MESHES
        renderEncoder?.pushDebugGroup("Skeletal Meshes Render")
            renderEncoder?.setRenderPipelineState(skeletalMeshPipelineState)
            scene.renderSkeletalMeshes(with: renderEncoder)
            scene.renderPlayer(with: renderEncoder)
        renderEncoder?.popDebugGroup()
        
        // WAYPOINTS
        renderEncoder?.pushDebugGroup("Waypoints Render")
            renderEncoder?.setRenderPipelineState(solidColorPipelineState)
            scene.renderWaypoints(with: renderEncoder)
        renderEncoder?.popDebugGroup()
        
        renderEncoder?.endEncoding()
    }
    
    private func render(in view: MTKView)
    {
        guard let drawable = view.currentDrawable else { return }

        let commandBuffer = Engine.commandQueue.makeCommandBuffer()
        commandBuffer?.label = "Main Pass Command Buffer"
        
        doMainRenderPass(with: commandBuffer, in: view)

        commandBuffer?.present(drawable)
        commandBuffer?.commit()
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

