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
    var shadowTexture: MTLTexture!
    
    private (set) var mesh = Mesh(modelName: "sphere")
    private (set) var lightData = LightData()
    
    private (set) var viewProjMatrix: matrix_float4x4 = matrix_identity_float4x4
    
    override init(name: String = "Light")
    {
        super.init(name: name)
        
        createShadowMap()
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
        var viewMatrix = transform.rotation.matrix
        
        viewMatrix.translate(direction: -transform.position)
        
        let projectionMatrix = matrix_float4x4.perspective(degreesFov: 90, aspectRatio: 1.0, near: 0.1, far: lightData.radius)
//        let projectionMatrix = matrix_float4x4.orthographic(width: lightData.radius * 2, height: lightData.radius * 2, length: lightData.radius)
        
        viewProjMatrix = projectionMatrix * viewMatrix;
    }
    
    private func createShadowMap()
    {
        let size: Int = 512
        
        let shadowTextureDescriptor = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .depth16Unorm,
                                                                                 size: size,
                                                                                 mipmapped: false)
        
        shadowTextureDescriptor.usage = [.renderTarget, .shaderRead]
        shadowTextureDescriptor.storageMode = .private
        
        shadowTexture = Engine.device.makeTexture(descriptor: shadowTextureDescriptor)!
        shadowTexture.label = name + " Shadow"
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
        lightData.radius = brightness
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
        let volumeScale = lightData.radius * 2
        
        mesh.transform = transform.matrix
        mesh.transform.scale(axis: float3(repeating: volumeScale))
        
        var lightData = lightData
        var view = CameraManager.shared.mainCamera.viewMatrix
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
