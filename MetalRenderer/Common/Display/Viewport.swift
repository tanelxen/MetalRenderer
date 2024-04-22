//
//  Viewport.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 03.09.2023.
//

import Foundation
import Metal
import simd

/**
 Класс Viewport инкапсулирует информацию о камере и render target'е
 И то и другое зависит от размеров области
 */
final class Viewport
{
    var camera: Camera? {
        didSet {
            camera?.updateViewport(width: width, height: height)
        }
    }
    
    private (set) var renderPass: MTLRenderPassDescriptor?
    
    private (set) var minBounds: float2 = .zero
    private (set) var maxBounds: float2 = float2(600, 600)
    
    // Для Retina всегда 2, для обычных - 1
    var dpi: Float = 2
    
    var texture: MTLTexture?
    
//    var textureRawPointer: UnsafeMutableRawPointer? {
//        withUnsafePointer(to: &texture) { ptr in
//            return UnsafeMutableRawPointer(mutating: ptr)
//        }
//    }
    
    var width: Int {
        Int(maxBounds.x - minBounds.x)
    }
    
    var height: Int {
        Int(maxBounds.y - minBounds.y)
    }
    
    var orthographicMatrix: float4x4 {
        let left: Float = 0
        let right: Float = Float(width)
        let top: Float = 0
        let bottom: Float = Float(height)
        
        let near: Float = -1
        let far: Float = 1
        
        return float4x4(
            [2 / (right - left), 0, 0, 0],
            [0, 2 / (top - bottom), 0, 0],
            [0, 0, -1 / (near - far), 0],
            [(left + right) / (left - right), (top + bottom) / (bottom - top), -far / (near - far), 1]
        )
    }
    
    private var framebufferWidth: Int {
        texture?.width ?? 1
    }
    
    private var framebufferHeight: Int {
        texture?.height ?? 1
    }
    
    private var resizeTask: DispatchWorkItem?
//    private var taskSize:
    
    func changeBounds(min: float2, max: float2)
    {
        minBounds = min
        maxBounds = max
        
        if width * Int(dpi) != framebufferWidth || height * Int(dpi) != framebufferHeight
        {
            camera?.updateViewport(width: width, height: height)
            createRenderPass()
        }
    }
    
    private func createRenderPass()
    {
        let width = width * Int(dpi)
        let height = height * Int(dpi)
        
        // ------ BASE COLOR 0 TEXTURE ------
        let colorTextureDecriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Preferences.colorPixelFormat,
                                                                             width: width,
                                                                             height: height,
                                                                             mipmapped: false)
        
        colorTextureDecriptor.usage = [.renderTarget, .shaderRead]
        let colorTexture = Engine.device.makeTexture(descriptor: colorTextureDecriptor)!
        
        // ------ DEPTH TEXTURE ------
        let depthTextureDecriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: Preferences.depthStencilPixelFormat,
                                                                             width: width,
                                                                             height: height,
                                                                             mipmapped: false)
        
        depthTextureDecriptor.usage = [.renderTarget, .shaderRead]
        depthTextureDecriptor.storageMode = .private
        let depthTexture = Engine.device.makeTexture(descriptor: depthTextureDecriptor)!
        
        // ------ RENDER PASS ------
        renderPass = MTLRenderPassDescriptor()
        
        renderPass?.colorAttachments[0].texture = colorTexture
        renderPass?.colorAttachments[0].storeAction = .store
        renderPass?.colorAttachments[0].loadAction = .clear
        
        renderPass?.depthAttachment.texture = depthTexture
        renderPass?.depthAttachment.storeAction = .store
        renderPass?.depthAttachment.loadAction = .clear
        
        self.texture = colorTexture
    }
    
    // 0, 0 - left, top
    // 1, 1 - right, bottom
    func mousePosition() -> float2
    {
        let positionX = minBounds.x
        let positionY = minBounds.y
        let sizeX = maxBounds.x - minBounds.x
        let sizeY = maxBounds.y - minBounds.y
        
        let mousePos = Mouse.getMouseWindowPosition()
        
        let x = (mousePos.x - positionX) / sizeX
        let y = (mousePos.y - positionY) / sizeY
        
        return float2(x, y)
    }
    
    func mousePositionInWorld() -> Ray
    {
        let mouse = mousePosition()
        
        let ndcX = mouse.x * 2 - 1
        let ndcY = (1 - mouse.y) * 2 - 1
        
        let clipCoords = float4(ndcX, ndcY, 0, 1)
        
        let viewProjInv = (camera!.projectionMatrix * camera!.viewMatrix).inverse
        
        var rayOrigin = viewProjInv * clipCoords
        rayOrigin /= rayOrigin.w
        
        var rayEnd = viewProjInv * float4(ndcX, ndcY, 1, 1)
        rayEnd /= rayEnd.w
        
        let rayDir = normalize(rayEnd - rayOrigin)
        
        return Ray(origin: rayOrigin.xyz, direction: rayDir.xyz)
    }
    
//    private func updateFramebufferSize(_ size: ImVec2)
//    {
//        guard taskSize != size else { return }
//
//        resizeTask?.cancel()
//
//        let task = DispatchWorkItem { [weak self] in
//            let size = CGSize(width: CGFloat(size.x), height: CGFloat(size.y))
//            self?.onViewportResized?(size)
//        }
//
//        resizeTask = task
//        taskSize = size
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
//    }
}
