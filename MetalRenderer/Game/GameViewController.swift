//
//  GameViewController.swift
//  Game
//
//  Created by Fedor Artemenkov on 10.09.2023.
//

import Cocoa
import Carbon
import MetalKit

final class GameViewController: NSViewController
{
    private var mtkView = MTKView()
    
    private var progressIndicator: NSProgressIndicator = {
        let view = NSProgressIndicator()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isDisplayedWhenStopped = false
        view.controlSize = .large
        view.style = .spinning
        view.setTintColor(NSColor(deviceRed: 255, green: 220, blue: 0, alpha: 150/255))
        return view
    }()
    
    private var mapName: String
    private var application: GameApplication?
    
    init(mapName: String)
    {
        self.mapName = mapName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView()
    {
        view = mtkView
        layout()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        application = GameApplication(view: self.mtkView)
        
        progressIndicator.startAnimation(nil)
        
        application?.startGame(mapName: mapName) { [weak self] in
            self?.progressIndicator.stopAnimation(nil)
            self?.setupEventsMonitor()
        }
    }
    
    override func viewDidAppear()
    {
        super.viewDidAppear()
        
        NSCursor.hide()
        CGAssociateMouseAndMouseCursorPosition(0)
    }
    
    override func viewDidDisappear()
    {
        super.viewDidDisappear()

        NSCursor.unhide()
        CGAssociateMouseAndMouseCursorPosition(1)
    }
    
    private func layout()
    {
        view.addSubview(progressIndicator)
        NSLayoutConstraint.activate([
            progressIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupEventsMonitor()
    {
        let mask: NSEvent.EventTypeMask = [
            .mouseMoved,
            .leftMouseDown, .leftMouseUp, .leftMouseDragged,
            .rightMouseDown, .rightMouseUp, .rightMouseDragged,
            .keyDown, .keyUp
        ]
        
        NSEvent.addLocalMonitorForEvents(matching: mask) { event -> NSEvent? in
            
            switch event.type
            {
                case .mouseMoved, .leftMouseDragged, .rightMouseDragged:
                    let deltaChange = float2(Float(event.deltaX), Float(event.deltaY))
                    
                    Mouse.setMousePositionChange(overallPosition: .zero,
                                                 deltaPosition: deltaChange)
                    
                case .leftMouseDown:
                    Mouse.setMouseButton(MouseCodes.left.rawValue, isPressed: true)
                    
                case .leftMouseUp:
                    Mouse.setMouseButton(MouseCodes.left.rawValue, isPressed: false)
                    
                case .keyDown:
                    if event.keyCode == kVK_Escape { exit(0) }
                    Keyboard.setKey(event.keyCode, isPressed: true)
                    
                case .keyUp:
                    Keyboard.setKey(event.keyCode, isPressed: false)
                    
                default:
                    return event
            }
            
            return nil
        }
    }
    
    deinit {
        print("deinit GameViewController")
    }
}

private extension NSProgressIndicator
{
    func setTintColor(_ tintColor: NSColor)
    {
        guard let adjustedTintColor = tintColor.usingColorSpace(.deviceRGB) else {
            contentFilters = []

            return
        }

        let tintColorRedComponent = adjustedTintColor.redComponent
        let tintColorGreenComponent = adjustedTintColor.greenComponent
        let tintColorBlueComponent = adjustedTintColor.blueComponent

        let tintColorMinComponentsVector = CIVector(x: tintColorRedComponent, y: tintColorGreenComponent, z: tintColorBlueComponent, w: 0.0)
        let tintColorMaxComponentsVector = CIVector(x: tintColorRedComponent, y: tintColorGreenComponent, z: tintColorBlueComponent, w: 1.0)

        let colorClampFilter = CIFilter(name: "CIColorClamp")!
        colorClampFilter.setDefaults()
        colorClampFilter.setValue(tintColorMinComponentsVector, forKey: "inputMinComponents")
        colorClampFilter.setValue(tintColorMaxComponentsVector, forKey: "inputMaxComponents")

        contentFilters = [colorClampFilter]
    }
}
