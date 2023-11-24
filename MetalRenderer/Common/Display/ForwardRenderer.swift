//
//  ForwardRenderer.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.02.2022.
//

import MetalKit

final class ForwardRenderer
{
    private var pipelineStates: PipelineStates! = PipelineStates()
    
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
    
    private var decalsStencilState: MTLDepthStencilState = {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.isDepthWriteEnabled = true
        descriptor.depthCompareFunction = .less
        descriptor.label = "Decal"
        return Engine.device.makeDepthStencilState(descriptor: descriptor)!
    }()
    
    private var billboardsStencilState: MTLDepthStencilState = {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.isDepthWriteEnabled = true
        descriptor.depthCompareFunction = .less
        descriptor.label = "Decal"
        return Engine.device.makeDepthStencilState(descriptor: descriptor)!
    }()
    
    private func drawScene(_ scene: Q3MapScene, with renderEncoder: MTLRenderCommandEncoder)
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
        
            renderEncoder.setFragmentTexture(nil, index: 1)
        renderEncoder.popDebugGroup()
        
        // SKELETAL MESHES
        renderEncoder.pushDebugGroup("Skeletal Meshes Render")
            renderEncoder.setRenderPipelineState(pipelineStates.skeletalMesh)
            scene.renderSkeletalMeshes(with: renderEncoder)
        renderEncoder.popDebugGroup()
    }
    
    private func drawDebug(with encoder: MTLRenderCommandEncoder)
    {
        encoder.pushDebugGroup("Debug Render")
        
        encoder.setFragmentTexture(nil, index: 0)
        
        encoder.setRenderPipelineState(pipelineStates.basic)
        
//        Q3MapScene.current?.brushes?.render(with: encoder)
        
        Debug.shared.render(with: encoder)
        
        encoder.setRenderPipelineState(pipelineStates.basicInst)
        Debug.shared.renderInstanced(with: encoder)
        
        encoder.popDebugGroup()
    }
    
    private func drawParticles(with encoder: MTLRenderCommandEncoder)
    {
        encoder.pushDebugGroup("Particles Render")
        
        encoder.setFragmentTexture(nil, index: 0)
        
        encoder.setDepthStencilState(skyStencilState)
        encoder.setRenderPipelineState(pipelineStates.particles)
        Particles.shared.render(with: encoder)
        
        encoder.popDebugGroup()
    }
    
    private func drawDecals(with encoder: MTLRenderCommandEncoder)
    {
        encoder.pushDebugGroup("Decals Render")
        
        encoder.setFragmentTexture(nil, index: 0)
        
        encoder.setDepthStencilState(decalsStencilState)
        encoder.setRenderPipelineState(pipelineStates.basicInst)
        Decals.shared.render(with: encoder)
        
        encoder.popDebugGroup()
    }
    
    private func drawBillboards(with encoder: MTLRenderCommandEncoder)
    {
        encoder.pushDebugGroup("Billboards Render")
        
        encoder.setFragmentTexture(nil, index: 0)
        
        encoder.setDepthStencilState(billboardsStencilState)
        encoder.setRenderPipelineState(pipelineStates.billboards)
        Billboards.shared.render(with: encoder)
        
        encoder.popDebugGroup()
    }
    
    private func drawUserInterface(in viewport: Viewport, with encoder: MTLRenderCommandEncoder)
    {
        encoder.pushDebugGroup("User Interface Render")
        
        encoder.setCullMode(.none)
        encoder.setDepthStencilState(skyStencilState)
        encoder.setRenderPipelineState(pipelineStates.userInterface)
        
        var matrix = viewport.orthographicMatrix
        encoder.setVertexBytes(&matrix, length: MemoryLayout<float4x4>.size, index: 1)
        
        UserInterface.shared.update(width: viewport.width, height: viewport.height)
        UserInterface.shared.draw(with: encoder)
        
        encoder.popDebugGroup()
    }
    
    func render(scene: Q3MapScene?, to viewport: Viewport, with commandBuffer: MTLCommandBuffer)
    {
        guard let pass = viewport.renderPass else { return }
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) else { return }
        
        var viewUniforms = SceneConstants()
        
        if let camera = viewport.camera
        {
            viewUniforms.viewMatrix = camera.viewMatrix
            viewUniforms.projectionMatrix = camera.projectionMatrix
            viewUniforms.viewportSize = viewport.maxBounds - viewport.minBounds
        }
        
        encoder.setVertexBytes(&viewUniforms, length: MemoryLayout<SceneConstants>.stride, index: 1)
        
        if let scene = scene
        {
            drawScene(scene, with: encoder)
        }
        
        drawBillboards(with: encoder)
        drawParticles(with: encoder)
        drawDecals(with: encoder)
        drawDebug(with: encoder)
        
//        if scene?.isPlaying ?? false
//        {
            drawUserInterface(in: viewport, with: encoder)
//        }
        
        encoder.endEncoding()
    }
    
    func render(scene: Q3MapScene, viewport: Viewport, in view: MTKView)
    {
        guard let commandBuffer = Engine.commandQueue.makeCommandBuffer() else { return }
        guard let drawable = view.currentDrawable else { return }
        
        commandBuffer.label = "Game Command Buffer"
        
        render(scene: scene, to: viewport, with: commandBuffer)
        
        // Copy the texture to the views drawable
        if let blitEncoder = commandBuffer.makeBlitCommandEncoder(), let texture = viewport.texture
        {
            blitEncoder.copy(from: texture, to: drawable.texture)
            blitEncoder.endEncoding()
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
