//
//  ForwardRenderer.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.02.2022.
//

import MetalKit

final class Renderer
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
    
    private var noneStencilState: MTLDepthStencilState = {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.isDepthWriteEnabled = false
        descriptor.depthCompareFunction = .always
        descriptor.label = "Always"
        return Engine.device.makeDepthStencilState(descriptor: descriptor)!
    }()
    
    private var commandBuffer: MTLCommandBuffer!
    private var commandEncoder: MTLRenderCommandEncoder!
    private var items: [RenderItem] = []
    
    func startFrame()
    {
        commandBuffer = Engine.commandQueue.makeCommandBuffer()
        commandBuffer.label = "Scene Command Buffer"
    }
    
    func draw(to viewport: Viewport, fillMode: MTLTriangleFillMode = .fill)
    {
        commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: viewport.renderPass!)
        
        var viewUniforms = SceneConstants()
        
        if let camera = viewport.camera
        {
            viewUniforms.viewMatrix = camera.viewMatrix
            viewUniforms.projectionMatrix = camera.projectionMatrix
            viewUniforms.viewportSize = viewport.maxBounds - viewport.minBounds
        }
        
        switch viewport.viewType
        {
            case .top, .perspective:
                viewUniforms.viewType = 0
                
            case .right:
                viewUniforms.viewType = 1
                
            case .back:
                viewUniforms.viewType = 2
        }
        
        commandEncoder.setVertexBytes(&viewUniforms, length: MemoryLayout<SceneConstants>.size, index: 1)
        
        for item in items
        {
            guard item.allowedViews.isEmpty || item.allowedViews.contains(viewport.viewType)
            else {
               continue
            }
            
            if let mtkMesh = item.mtkMesh
            {
                item.transform.updateModelMatrix()
                
                var modelConstants = ModelConstants()
                modelConstants.color = item.tintColor
                modelConstants.modelMatrix = item.transform.matrix
                modelConstants.useFlatShading = 1
                commandEncoder.setVertexBytes(&modelConstants, length: MemoryLayout<ModelConstants>.stride, index: 2)
                commandEncoder.setTriangleFillMode(.fill)
                commandEncoder.setFragmentTexture(item.texture, index: 0)
                mtkMesh.render(with: commandEncoder)
                continue
            }
            
            apply(technique: item.technique, to: commandEncoder)
            commandEncoder.setCullMode(item.cullMode)
            
            item.transform.updateModelMatrix()
            
            var modelConstants = ModelConstants()
            modelConstants.color = item.tintColor
            modelConstants.modelMatrix = item.transform.matrix
            modelConstants.useFlatShading = 1
            commandEncoder.setVertexBytes(&modelConstants, length: MemoryLayout<ModelConstants>.stride, index: 2)
            
            commandEncoder.setVertexBuffer(item.vertexBuffer, offset: 0, index: 0)
            commandEncoder.setFragmentTexture(item.texture, index: 0)
            
            if item.isSupportLineMode && fillMode == .lines
            {
                commandEncoder.setTriangleFillMode(.lines)
            }
            else
            {
                commandEncoder.setTriangleFillMode(.fill)
            }
            
            if item.numIndices > 0
            {
                commandEncoder.drawIndexedPrimitives(type: item.primitiveType,
                                                     indexCount: item.numIndices,
                                                     indexType: .uint16,
                                                     indexBuffer: item.indexBuffer,
                                                     indexBufferOffset: 0)
            }
            else
            {
                commandEncoder.drawPrimitives(type: item.primitiveType, vertexStart: 0, vertexCount: item.numVertices)
            }
        }
        
        drawDebug(with: commandEncoder)
        
        commandEncoder.endEncoding()
    }
    
    func add(item: RenderItem)
    {
        items.append(item)
    }
    
    func endFrame()
    {
        commandBuffer.commit()
        items.removeAll(keepingCapacity: true)
    }
    
    func apply(technique: RenderTechnique, to encoder: MTLRenderCommandEncoder)
    {
        switch technique
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
                
            case .dot:
                encoder.setCullMode(.none)
                encoder.setDepthStencilState(noneStencilState)
                encoder.setRenderPipelineState(pipelineStates.dot)
        }
    }
    
    private func drawDebug(with encoder: MTLRenderCommandEncoder)
    {
        apply(technique: .basic, to: encoder)
        Debug.shared.render(with: encoder)
        
        encoder.setRenderPipelineState(pipelineStates.basicInst)
        Debug.shared.renderInstanced(with: encoder)
    }
}

struct RenderItem
{
    var technique: RenderTechnique!
    
    var cullMode: MTLCullMode = .none
    var transform: Transform = Transform()
    
    var vertexBuffer: MTLBuffer!
    var numVertices: Int = 0
    
    var indexBuffer: MTLBuffer!
    var numIndices: Int = 0
    
    var primitiveType: MTLPrimitiveType = .triangle
    
    var mtkMesh: MTKGeometry?
    
    var tintColor: float4 = .one
    var texture: MTLTexture?
    
    var isSupportLineMode = false
    
    var allowedViews: Set<ViewType> = []
}

enum RenderTechnique
{
    case basic
    case brush
    case grid
    case dot
}
