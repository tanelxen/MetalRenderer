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
    
    private var gridStencilState: MTLDepthStencilState = {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.isDepthWriteEnabled = false
        descriptor.depthCompareFunction = .less
        descriptor.label = "Grid"
        return Engine.device.makeDepthStencilState(descriptor: descriptor)!
    }()
    
    func render(scene: BrushScene, to viewport: Viewport, with commandBuffer: MTLCommandBuffer)
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
        
        encoder.setVertexBytes(&viewUniforms, length: MemoryLayout<SceneConstants>.size, index: 1)
        
        drawScene(scene, with: encoder)
        drawDebug(with: encoder)
        
        encoder.endEncoding()
    }
    
    func apply(tehnique: RenderTechnique, to encoder: MTLRenderCommandEncoder)
    {
        switch tehnique
        {
            case .basic:
                encoder.setCullMode(.back)
                encoder.setFrontFacing(.clockwise)
                encoder.setDepthStencilState(regularStencilState)
                encoder.setRenderPipelineState(pipelineStates.basic)
                
            case .brush:
                encoder.setCullMode(.back)
                encoder.setFrontFacing(.counterClockwise)
                encoder.setDepthStencilState(regularStencilState)
                encoder.setRenderPipelineState(pipelineStates.brush)
                
            case .grid:
                encoder.setCullMode(.none)
                encoder.setFrontFacing(.clockwise)
                encoder.setDepthStencilState(gridStencilState)
                encoder.setRenderPipelineState(pipelineStates.simpleGrid)
        }
    }
    
    private func drawScene(_ scene: BrushScene, with encoder: MTLRenderCommandEncoder)
    {
        scene.render(with: encoder, to: self)
    }
    
    private func drawDebug(with encoder: MTLRenderCommandEncoder)
    {
        encoder.setRenderPipelineState(pipelineStates.basic)
        
        Debug.shared.render(with: encoder)
        
        encoder.setRenderPipelineState(pipelineStates.basicInst)
        Debug.shared.renderInstanced(with: encoder)
    }
}
