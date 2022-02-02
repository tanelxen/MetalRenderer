//
//  LightNode.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

class LightNode: Node
{
    var shouldCastShadow = true
    
    private (set) var mesh = Mesh(modelName: "sphere")
    private (set) var lightData = LightData()
    
    private (set) var viewProjMatrix: matrix_float4x4 = matrix_identity_float4x4
    
    override init(name: String = "Light")
    {
        super.init(name: name)
    }

    override func update()
    {
//        doUpdate()
        lightData.position = transform.position
        
        if shouldCastShadow
        {
            updateShadowMatrix()
        }
    }
    
    override func render(with encoder: MTLRenderCommandEncoder?, useMaterials: Bool)
    {
    }
    
    func updateShadowMatrix()
    {
        var viewMatrix = matrix_identity_float4x4
        
        viewMatrix.rotate(angle: transform.rotation.x, axis: .x_axis)
        viewMatrix.rotate(angle: transform.rotation.y, axis: .y_axis)
        viewMatrix.rotate(angle: transform.rotation.z, axis: .z_axis)
        
        viewMatrix.translate(direction: -transform.position)
        
        let volumeScale = lightData.brightness * 2
        
        let projectionMatrix = matrix_float4x4.perspective(degreesFov: 45, aspectRatio: 1.0, near: 0.1, far: volumeScale)
//        let projectionMatrix = matrix_float4x4.orthographic(width: volumeScale, height: volumeScale, length: volumeScale)
        
        viewProjMatrix = projectionMatrix * viewMatrix;
    }
}

extension LightNode
{
    func setLight(color: float3)
    {
        lightData.color = color
    }
    
    func setLight(brightness: Float)
    {
        lightData.brightness = brightness
    }
    
    func setLight(ambientIntensity: Float)
    {
        lightData.ambientIntensity = ambientIntensity
    }
}

extension LightNode
{
    func renderVolume(with encoder: MTLRenderCommandEncoder?)
    {
        let volumeScale = lightData.brightness * 2
        
        mesh.transform = transform.matrix
        mesh.transform.scale(axis: float3(repeating: volumeScale))
        
        var lightData = lightData
        var view = DebugCamera.shared.viewMatrix
        var lightSpaceMatrix = viewProjMatrix
        
        encoder?.setFragmentBytes(&lightSpaceMatrix, length: MemoryLayout<matrix_float4x4>.stride, index: 3)
        
        encoder?.setFragmentBytes(&lightData, length: LightData.stride, index: 0)
        encoder?.setFragmentBytes(&view, length: MemoryLayout<matrix_float4x4>.stride, index: 2)
        
        mesh.doRender(with: encoder, useMaterials: false)
    }
    
//    func castShadow(with encoder: MTLRenderCommandEncoder?)
//    {
//        mesh.transform = transform.matrix
//        
////        var lightData = lightData
////        var view = DebugCamera.shared.viewMatrix
//        
////        encoder?.setFragmentBytes(&lightData, length: LightData.stride, index: 0)
////        encoder?.setFragmentBytes(&view, length: MemoryLayout<matrix_float4x4>.stride, index: 2)
//        
//        mesh.doRender(with: encoder, useMaterials: true)
//    }
}
