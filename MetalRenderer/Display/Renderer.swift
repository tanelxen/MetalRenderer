//
//  Renderer.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 13.01.2022.
//

import MetalKit

class Renderer: NSObject
{
    static private (set) var screenSize: float2 = .zero
    
    static var aspectRatio: Float {
        guard screenSize.y > 0 else { return 1 }
        return screenSize.x / screenSize.y
    }
    
    private let scene = SandboxScene()
    
    init(view: MTKView)
    {
        super.init()
        
        updateScreenSize(view.bounds.size)
    }
    
    private func updateScreenSize(_ size: CGSize)
    {
        Renderer.screenSize.x = Float(size.width)
        Renderer.screenSize.y = Float(size.height)
    }
    
    fileprivate func update(in view: MTKView)
    {
        let dt = 1.0 / Float(view.preferredFramesPerSecond)
        GameTime.update(deltaTime: dt)
        
        scene.update()
    }
}

extension Renderer: MTKViewDelegate
{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize)
    {
        updateScreenSize(size)
    }
    
    func draw(in view: MTKView)
    {
        update(in: view)
        
        guard let drawable = view.currentDrawable else { return }
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        let commandBuffer = Engine.commandQueue.makeCommandBuffer()
        let renderCommandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        scene.render(with: renderCommandEncoder)
        
        renderCommandEncoder?.endEncoding()
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
