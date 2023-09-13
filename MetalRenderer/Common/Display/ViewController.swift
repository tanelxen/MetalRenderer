//
//  ViewController.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 09.09.2023.
//

import Cocoa
import MetalKit

class ViewController: NSViewController
{
    let mtkView = MTKView()
    
    override func loadView()
    {
        view = mtkView
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        mtkView.clearColor = .init(red: 0.02, green: 0.02, blue: 0.03, alpha: 1.0)
        mtkView.colorPixelFormat = Preferences.colorPixelFormat
        mtkView.depthStencilPixelFormat = Preferences.depthStencilPixelFormat
        mtkView.framebufferOnly = false
        
        mtkView.device = MTLCreateSystemDefaultDevice()
    }
    
    override func mouseMoved(with event: NSEvent)
    {
        mouseEventCallback?(event)
    }
    
    override func mouseDown(with event: NSEvent)
    {
        mouseEventCallback?(event)
    }
    
    override func mouseUp(with event: NSEvent)
    {
        mouseEventCallback?(event)
    }
    
    override func mouseDragged(with event: NSEvent)
    {
        mouseEventCallback?(event)
    }
    
    override func rightMouseDown(with event: NSEvent)
    {
        mouseEventCallback?(event)
    }
    
    override func rightMouseUp(with event: NSEvent)
    {
        mouseEventCallback?(event)
    }
    
    override func rightMouseDragged(with event: NSEvent)
    {
        mouseEventCallback?(event)
    }
    
    override func otherMouseDown(with event: NSEvent)
    {
        mouseEventCallback?(event)
    }
    
    override func otherMouseUp(with event: NSEvent)
    {
        mouseEventCallback?(event)
    }
    
    override func otherMouseDragged(with event: NSEvent)
    {
        mouseEventCallback?(event)
    }
    
    override func scrollWheel(with event: NSEvent)
    {
        mouseEventCallback?(event)
    }
    
    override
}
