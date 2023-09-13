//
//  Application.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 03.09.2023.
//

import Foundation
import ApplicationServices
import MetalKit
import ImGui

final class SandboxApplication: NSObject
{
    var view: MTKView
    
    private var viewport: Viewport!
    private var renderer: ForwardRenderer!
    private var scene: Q3MapScene!
    
    private var editor: EditorLayer?
    
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
        
        editor = EditorLayer(view: view, sceneViewport: viewport)
        
        editor?.onLoadNewMap = { [weak self] name in
            self?.scene = Q3MapScene(name: name)
            self?.viewport.camera?.transform.position = .zero
            self?.viewport.camera?.transform.rotation = .zero
        }
        
        view.delegate = self
        
        setupEventsMonitor()
        
        AudioEngine.start()
    }
    
    private func setupEventsMonitor()
    {
        let mask: NSEvent.EventTypeMask = [
            .mouseMoved,
            .leftMouseDown, .leftMouseUp, .leftMouseDragged,
            .rightMouseDown, .rightMouseUp, .rightMouseDragged,
            .keyDown, .keyUp
        ]
        
        NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event -> NSEvent? in
            self?.handleEvent(event)
            return event
        }
    }
    
    private func handleEvent(_ event: NSEvent)
    {
        editor?.handleEvent(event)
    }
    
    private func update()
    {
        GameTime.update()
        
        guard let viewport = self.viewport else { return }
        
        scene?.update()
        viewport.camera?.update()
        
        if let commandBuffer = Engine.commandQueue.makeCommandBuffer()
        {
            commandBuffer.label = "Scene Command Buffer"

            renderer?.render(scene: scene, to: viewport, with: commandBuffer)
            
            commandBuffer.commit()
        }
        
        editor?.draw()
    }
}

extension SandboxApplication: MTKViewDelegate
{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize)
    {
    }
    
    func draw(in view: MTKView)
    {
        update()
    }
}
