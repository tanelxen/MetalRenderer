//
//  RendererView.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 11.01.2022.
//

import MetalKit

class GameView: MTKView
{
    private var renderer: MTKViewDelegate!
    private let hudView = HudView()
    
    init()
    {
        super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())
        
        Engine.ignite(device: device!)
        
        self.clearColor = .init(red: 0.02, green: 0.02, blue: 0.03, alpha: 1.0)
        self.colorPixelFormat = Preferences.colorPixelFormat
        self.depthStencilPixelFormat = Preferences.depthStencilPixelFormat
        
        renderer = ForwardRenderer(view: self)
        
        self.delegate = renderer
        
        
        addSubview(hudView)
        hudView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hudView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor),
            hudView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor),
            hudView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            hudView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension GameView
{
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent)
    {
        Keyboard.setKey(event.keyCode, isPressed: true)
    }
    
    override func keyUp(with event: NSEvent)
    {
        Keyboard.setKey(event.keyCode, isPressed: false)
    }
}

extension GameView
{
    override func mouseDown(with event: NSEvent)
    {
         Mouse.setMouseButton(event.buttonNumber, isPressed: true)
    }
    
    override func mouseUp(with event: NSEvent)
    {
         Mouse.setMouseButton(event.buttonNumber, isPressed: false)
    }
    
    override func rightMouseDown(with event: NSEvent)
    {
         Mouse.setMouseButton(event.buttonNumber, isPressed: true)
    }
    
    override func rightMouseUp(with event: NSEvent)
    {
         Mouse.setMouseButton(event.buttonNumber, isPressed: false)
    }
    
    override func otherMouseDown(with event: NSEvent)
    {
         Mouse.setMouseButton(event.buttonNumber, isPressed: true)
    }
    
    override func otherMouseUp(with event: NSEvent)
    {
         Mouse.setMouseButton(event.buttonNumber, isPressed: false)
    }
}

// --- Mouse Movement ---
extension GameView
{
    override func mouseMoved(with event: NSEvent)
    {
         setMousePositionChanged(event: event)
    }
    
    override func scrollWheel(with event: NSEvent)
    {
         Mouse.scrollWheel(Float(event.deltaY))
    }
    
    override func mouseDragged(with event: NSEvent)
    {
         setMousePositionChanged(event: event)
    }
    
    override func rightMouseDragged(with event: NSEvent)
    {
         setMousePositionChanged(event: event)
    }
    
    override func otherMouseDragged(with event: NSEvent)
    {
         setMousePositionChanged(event: event)
    }
    
    private func setMousePositionChanged(event: NSEvent)
    {
         let overallLocation = float2(Float(event.locationInWindow.x),
                                      Float(event.locationInWindow.y))
         let deltaChange = float2(Float(event.deltaX),
                                  Float(event.deltaY))
        
         Mouse.setMousePositionChange(overallPosition: overallLocation,
                                      deltaPosition: deltaChange)
    }
    
    override func updateTrackingAreas()
    {
         let area = NSTrackingArea(rect: self.bounds,
                                   options: [NSTrackingArea.Options.activeAlways,
                                             NSTrackingArea.Options.mouseMoved,
                                             NSTrackingArea.Options.enabledDuringMouseDrag],
                                   owner: self,
                                   userInfo: nil)
         self.addTrackingArea(area)
    }
    
}
