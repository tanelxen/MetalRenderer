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
    
    private var pipelineStates: PipelineStates!
    
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
        
        pipelineStates = PipelineStates()
        
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
    
    // MARK: - DO PASSES
    
    private func doMainRenderPass(with renderEncoder: MTLRenderCommandEncoder)
    {
        guard scene.isReady else { return }
        
        renderEncoder.label = "Main Pass Command Encoder"
        
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setCullMode(.back)
        
        // SKYBOX
        renderEncoder.pushDebugGroup("Skybox Render")
            renderEncoder.setDepthStencilState(skyStencilState)
            renderEncoder.setRenderPipelineState(pipelineStates.skybox)
            scene.renderSky(with: renderEncoder)
        renderEncoder.popDebugGroup()
        
        renderEncoder.setFrontFacing(.clockwise)
        renderEncoder.setCullMode(.back)
        
        renderEncoder.setDepthStencilState(regularStencilState)
        
        // WORLD MESH
        renderEncoder.pushDebugGroup("World Mesh Render")
            renderEncoder.setRenderPipelineState(pipelineStates.worldMeshLightmapped)
            scene.renderWorldLightmapped(with: renderEncoder)
        
            renderEncoder.setRenderPipelineState(pipelineStates.worldMeshVertexlit)
            scene.renderWorldVertexlit(with: renderEncoder)
        renderEncoder.popDebugGroup()
        
        // SKELETAL MESHES
        renderEncoder.pushDebugGroup("Skeletal Meshes Render")
            renderEncoder.setRenderPipelineState(pipelineStates.skeletalMesh)
            scene.renderSkeletalMeshes(with: renderEncoder)
        renderEncoder.popDebugGroup()
        
        // DEBUG
        renderEncoder.pushDebugGroup("Debug Render")
            renderEncoder.setRenderPipelineState(pipelineStates.solidColor)
            Debug.shared.render(with: renderEncoder)
        
            renderEncoder.setRenderPipelineState(pipelineStates.solidColorInst)
            Debug.shared.renderInstanced(with: renderEncoder)
        renderEncoder.popDebugGroup()
    }
    
    private func render(in view: MTKView)
    {
        guard let drawable = view.currentDrawable else { return }
        guard let passDescriptor = view.currentRenderPassDescriptor else { return }
        guard let commandBuffer = Engine.commandQueue.makeCommandBuffer() else { return }
        
        commandBuffer.label = "Main Pass Command Buffer"
        
        if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
        {
            doMainRenderPass(with: renderEncoder)
            renderEncoder.endEncoding()
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
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

