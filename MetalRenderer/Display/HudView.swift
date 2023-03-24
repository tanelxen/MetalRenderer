//
//  GameUIView.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 23.03.2023.
//

import Cocoa

class HudView: NSView
{
    static let shared = HudView()
    
    var gameState: GameState = .start
    {
        didSet
        {
            switch gameState
            {
                case .start:
                    crosshairView2.isHidden = true
                    crosshairView3.isHidden = true
                    healthView.isHidden = true
                    
                case .loading:
                    crosshairView2.isHidden = true
                    crosshairView3.isHidden = true
                    healthView.isHidden = true
                    loaderView.startAnimation(nil)
                    
                case .ready:
                    crosshairView2.isHidden = false
                    crosshairView3.isHidden = false
                    healthView.isHidden = false
                    loaderView.stopAnimation(nil)
            }
        }
    }
    
    enum GameState
    {
        case start
        case loading
        case ready
    }
    
    private let loaderView: NSProgressIndicator = {
        let view = NSProgressIndicator()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isDisplayedWhenStopped = false
        view.controlSize = .large
        view.style = .spinning
        view.set(tintColor: hudMainColor)
        return view
    }()
    
    private let hintLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .black.withAlphaComponent(0.5)
        label.alphaValue = 0.5
        label.textColor = .white
        label.isBezeled = false
        label.isEditable = false
        label.stringValue = """
Controls:
•‎ WASD: Move
•‎ RMB: Look around
•‎ Q: Place new waypoint
•‎ E: Remove waypoint
•‎ R: Rebuild navigation graph
•‎ N: Move bot at player position
"""
        return label
    }()
    
    private let crosshairView2: NSView = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont(name: "HalfLife2", size: 40)
        label.backgroundColor = .clear
        label.textColor = hudMainColor
        label.isBezeled = false
        label.isEditable = false
        label.alignment = .center
        label.stringValue = "Q"
        return label
    }()
    
    private let crosshairView3: NSView = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont(name: "HalfLife2", size: 80)
        label.backgroundColor = .clear
        label.textColor = hudMainColor
        label.isBezeled = false
        label.isEditable = false
        label.alignment = .center
        label.stringValue = "{  }"
        return label
    }()
    
    private static let hudBackgroundColor = NSColor(deviceRed: 0, green: 0, blue: 0, alpha: 76/255)
    private static let hudTextColor = NSColor(deviceRed: 255, green: 220, blue: 0, alpha: 150/255)
    private static let hudMainColor = NSColor(deviceRed: 255, green: 220, blue: 0, alpha: 150/255)
    
    private let healthView: NSView = {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsLayer = true
        view.layer?.backgroundColor = hudBackgroundColor.cgColor
        view.layer?.cornerRadius = 8
        view.widthAnchor.constraint(equalToConstant: 227).isActive = true
        view.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        return view
    }()
    
    private let healthTitleLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont(name: "Verdana-Bold", size: 17)
        label.backgroundColor = .clear
        label.textColor = hudTextColor
        label.isBezeled = false
        label.isEditable = false
        label.stringValue = "HEALTH"
        return label
    }()
    
    private let healthValueLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont(name: "HalfLife2", size: 62)
        label.backgroundColor = .clear
        label.textColor = hudTextColor
        label.isBezeled = false
        label.isEditable = false
        label.stringValue = "100"
        return label
    }()
    
    private override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
//        addSubview(hintLabel)
//        NSLayoutConstraint.activate([
//            hintLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
//            hintLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 8)
//        ])
        
        addSubview(healthView)
        NSLayoutConstraint.activate([
            healthView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -28),
            healthView.leftAnchor.constraint(equalTo: leftAnchor, constant: 38)
        ])
        
        healthView.addSubview(healthTitleLabel)
        NSLayoutConstraint.activate([
            healthTitleLabel.bottomAnchor.constraint(equalTo: healthView.bottomAnchor, constant: -16),
            healthTitleLabel.leftAnchor.constraint(equalTo: healthView.leftAnchor, constant: 16)
        ])
        
        healthView.addSubview(healthValueLabel)
        NSLayoutConstraint.activate([
            healthValueLabel.topAnchor.constraint(equalTo: healthView.topAnchor, constant: 0),
            healthValueLabel.bottomAnchor.constraint(equalTo: healthView.bottomAnchor, constant: 0),
            healthValueLabel.leftAnchor.constraint(equalTo: healthView.leftAnchor, constant: 112)
        ])
        
        addSubview(crosshairView2)
        NSLayoutConstraint.activate([
            crosshairView2.centerXAnchor.constraint(equalTo: centerXAnchor),
            crosshairView2.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 2)
        ])
        
        addSubview(crosshairView3)
        NSLayoutConstraint.activate([
            crosshairView3.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 1),
            crosshairView3.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -7)
        ])
        
        addSubview(loaderView)
        NSLayoutConstraint.activate([
            loaderView.centerXAnchor.constraint(equalTo: centerXAnchor),
            loaderView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        
        gameState = .start
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension NSProgressIndicator {

    func set(tintColor: NSColor) {
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
