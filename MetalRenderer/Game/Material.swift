//
//  Material.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 15.01.2022.
//

import MetalKit

class Material
{
    var pipelineStateType: RenderPipelineStateTypes = .basic
    var materialConstants = MaterialConstants()
    var textureType: TextureTypes = .none
}

extension Material
{
    func setColor(_ color: float4)
    {
        materialConstants.color = color
        materialConstants.useColor = true
        materialConstants.useTexture = false
    }
    
    func setTexture(_ textureType: TextureTypes)
    {
        materialConstants.useColor = false
        materialConstants.useTexture = true
        self.textureType = textureType
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
        encoder?.setRenderPipelineState(RenderPipelineStateLibrary[pipelineStateType])
        
        // Fragment shader setup
        encoder?.setFragmentSamplerState(SamplerStateLibrary[.linear], index: 0)
        encoder?.setFragmentBytes(&materialConstants, length: MaterialConstants.stride, index: 1)
        
        if materialConstants.useTexture
        {
            encoder?.setFragmentTexture(TextureLibrary[textureType], index: 0)
        }
    }
}
