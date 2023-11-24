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
    
    private let workingDirLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = NSColor(deviceRed: 255, green: 220, blue: 0, alpha: 100/255)
        label.font = .systemFont(ofSize: 12)
        label.drawsBackground = false
        label.isEditable = false
        label.isBezeled = false
        return label
    }()
    
    private let stackView: NSStackView = {
        let stackView = NSStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .leading
        stackView.spacing = 10
        return stackView
    }()
    
    private var gameViewController: NSViewController?
    
    private var mapsDir: URL? {
        
        guard let workingDir = UserDefaults.standard.url(forKey: "workingDir")
        else {
            return nil
        }
        
        let maps = workingDir.appendingPathComponent("Assets/maps")
        
        guard FileManager.default.fileExists(atPath: maps.path)
        else {
            return nil
        }
        
        return maps
    }
    
    private var items: [URL] {
        
        guard let dir = self.mapsDir else { return [] }
        
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.isPackageKey, .isDirectoryKey],
            options: .skipsHiddenFiles
        ) else { return [] }
        
        return urls.filter {
            $0.pathExtension == "wld"
        }
    }
    
    override func loadView()
    {
        view = NSView()
        layout()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let workingDir = UserDefaults.standard.url(forKey: "workingDir")
        workingDirLabel.stringValue = "Working dir: " + (workingDir?.path ?? "")
        
        let listTitleLabel: NSTextField = {
            let label = NSTextField()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textColor = NSColor(deviceRed: 255, green: 220, blue: 0, alpha: 100/255)
            label.font = .systemFont(ofSize: 20)
            label.isEditable = false
            label.isBezeled = false
            label.drawsBackground = false
            label.stringValue = "Available scenes:"
            label.sizeToFit()
            return label
        }()
        
        stackView.addArrangedSubview(listTitleLabel)

        let names = items
            .map {
                $0.deletingPathExtension().lastPathComponent
            }
            .sorted()
        
        for (index, name) in names.enumerated()
        {
            let button = NSButton(title: name, target: self, action: #selector(playMap))
            button.font = .systemFont(ofSize: 20, weight: .regular)
            button.contentTintColor = NSColor(deviceRed: 255, green: 220, blue: 0, alpha: 150/255)
            button.showsBorderOnlyWhileMouseInside = true
            button.isBordered = false
            button.tag = index
            
            stackView.addArrangedSubview(button)
        }
    }
    
    @objc private func playMap(_ sender: NSButton)
    {
        guard sender.tag < items.count else { return }
        
        let mapURL = items[sender.tag]
        
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
        
        view.addSubview(workingDirLabel)
        NSLayoutConstraint.activate([
            workingDirLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            workingDirLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0)
        ])
    }
}
