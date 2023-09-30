//
//  MenuViewController.swift
//  Game
//
//  Created by Fedor Artemenkov on 11.09.2023.
//

import Cocoa

final class MenuViewController: NSViewController
{
    private let imageView: NSImageView = {
        let imageView = NSImageView()
        imageView.image = NSImage(named: "menu_background")
        imageView.imageScaling = NSImageScaling.scaleAxesIndependently
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let stackView: NSStackView = {
        let stackView = NSStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .leading
        stackView.spacing = 10
        return stackView
    }()
    
    private var gameViewController: NSViewController?
    
    private var mapURLs: [URL] = []
    
    override func loadView()
    {
        view = NSView()
        layout()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        mapURLs = Bundle.main.urls(forResourcesWithExtension: "bsp", subdirectory: "Assets/q3/maps/") ?? []
        
        let names = mapURLs
            .map {
                $0.deletingPathExtension().lastPathComponent
            }
            .sorted()
        
        for (index, name) in names.enumerated()
        {
            let button = NSButton(title: name, target: self, action: #selector(playMap))
            button.font = NSFont(name: "HalfLife", size: 20)
            button.contentTintColor = NSColor(deviceRed: 255, green: 220, blue: 0, alpha: 150/255)
            button.showsBorderOnlyWhileMouseInside = true
            button.isBordered = false
            button.tag = index
            
            stackView.addArrangedSubview(button)
        }
    }
    
    @objc private func playMap(_ sender: NSButton)
    {
        guard sender.tag < mapURLs.count else { return }
        
        let mapURL = mapURLs[sender.tag]
        
        let vc = GameViewController(mapURL: mapURL)
        view.window?.contentView = vc.view
        view.window?.makeKeyAndOrderFront(nil)
        view.window?.acceptsMouseMovedEvents = true
        
        gameViewController = vc
    }
    
    private func layout()
    {
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leftAnchor.constraint(equalTo: view.leftAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 40)
        ])
    }
}
