//
//  GameApplication.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 10.09.2023.
//

import Foundation
import MetalKit
import Carbon

final class GameApplication: NSObject
{
    var view: MTKView
    
    private var viewport: Viewport!
    private var renderer: ForwardRenderer!
    private var scene: Q3MapScene!
    
    init(view: MTKView)
    {
        self.view = view
        super.init()
        
        view.clearColor = .init(red: 0.02, green: 0.02, blue: 0.03, alpha: 1.0)
        view.colorPixelFormat = Preferences.colorPixelFormat
        view.depthStencilPixelFormat = Preferences.depthStencilPixelFormat
        view.framebufferOnly = false
        
        view.device = MTLCreateSystemDefaultDevice()
        
        Engine.ignite(device: view.device!)
        
        renderer = ForwardRenderer()
        
        viewport = Viewport()
//        viewport.dpi = Float(view.window?.backingScaleFactor ?? 2.0)
        
        view.delegate = self
        
        AudioEngine.start()
    }
    
    func startGame(mapName: String, completionHandler: (()->Void)?)
    {
        scene = Q3MapScene(name: mapName)
        
        scene.onReady = { [unowned self] in
            completionHandler?()
            scene.startPlaying(in: viewport)
        }
    }
    
    private func update()
    {
        GameTime.update()
        
        guard let viewport = self.viewport else { return }
        guard let scene = self.scene else { return }
        
        scene.update()
        viewport.camera?.update()
        
        renderer?.render(scene: scene, viewport: viewport, in: view)
    }
}

extension GameApplication: MTKViewDelegate
{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize)
    {
        let width = Float(view.bounds.width)
        let height = Float(view.bounds.height)

        viewport.changeBounds(min: .zero, max: float2(width, height))
    }
    
    func draw(in view: MTKView)
    {
        update()
    }
}

