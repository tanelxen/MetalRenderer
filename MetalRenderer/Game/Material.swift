//
//  Material.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 15.01.2022.
//

import MetalKit

class Material
{
//    var pipelineStateType: RenderPipelineStateTypes = .basic
    var materialConstants = MaterialConstants()
    
    var baseColorMap: MTLTexture?
    var normalMap: MTLTexture?
}

extension Material
{
    func setColor(_ color: float4)
    {
        materialConstants.color = color
    }
    
    func setBaseColorMap(_ texture: MTLTexture)
    {
        self.baseColorMap = texture
        self.materialConstants.useBaseColorMap = true
    }
    
    func setNormalMap(_ texture: MTLTexture)
    {
        self.normalMap = texture
    }
    
    func setMaterial(isLit: Bool)
    {
        materialConstants.isLit = isLit
    }
    
    func setMaterial(ambient: float3)
    {
        materialConstants.ambient = ambient
    }
}

extension Material
{
    func apply(to encoder: MTLRenderCommandEncoder?)
    {
//        encoder?.setRenderPipelineState(RenderPipelineStateLibrary[pipelineStateType])
        
        // Fragment shader setup
//        encoder?.setFragmentSamplerState(SamplerStateLibrary[.linear], index: 0)
        encoder?.setFragmentBytes(&materialConstants, length: MaterialConstants.stride, index: 1)
        
        if let texture = self.baseColorMap
        {
            encoder?.setFragmentTexture(texture, index: 0)
        }
        
        if let texture = self.normalMap
        {
            encoder?.setFragmentTexture(texture, index: 1)
        }
    }
}
