//
//  main.swift
//  Sandbox
//
//  Created by Fedor Artemenkov on 10.09.2023.
//

import Cocoa
import MetalKit

class AppDelegate: NSObject, NSApplicationDelegate
{
    var window: NSWindow?
    var application: SandboxApplication?

    func applicationDidFinishLaunching(_ notification: Notification)
    {
        let frame = NSScreen.main!.frame
        
        window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: frame.width, height: frame.height),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered,
                          defer: false)
        window?.title = "Sandbox"
        window?.center()
        
        let view = DragDropView()
        application = SandboxApplication(view: view)
        
        view.onDropFile = { [weak self] url in
            self?.application?.dropFile(url)
        }
        
        window?.contentView = view
        window?.makeKeyAndOrderFront(nil)
        window?.acceptsMouseMovedEvents = true
        
        createMenu()
        
        let types: [NSPasteboard.PasteboardType] = [.fileURL]
        view.registerForDraggedTypes(types)
        
#if DEBUG
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
#endif
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    private func createMenu()
    {
        let appMenu = NSMenuItem()
        appMenu.submenu = NSMenu()
        let appName = ProcessInfo.processInfo.processName
        appMenu.submenu?.addItem(NSMenuItem(title: "About \(appName)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.submenu?.addItem(NSMenuItem(title: "Quit \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        let fileMenu = NSMenuItem()
        fileMenu.submenu = NSMenu(title: "File")
        fileMenu.submenu?.items = [
            NSMenuItem(title: "Open map", action: #selector(openMap), keyEquivalent: ""),
            NSMenuItem(title: "Save map", action: #selector(saveMap), keyEquivalent: "")
        ]

        let settingsMenu = NSMenuItem()
        settingsMenu.submenu = NSMenu(title: "Settings")
        settingsMenu.submenu?.items = [
            NSMenuItem(title: "Change working directory", action: #selector(changeDir), keyEquivalent: "")
        ]
        
        let mainMenu = NSMenu(title: "Main Menu")
        mainMenu.addItem(appMenu)
        mainMenu.addItem(fileMenu)
        mainMenu.addItem(settingsMenu)
        
        NSApp.mainMenu = mainMenu
    }
    
    @objc private func changeDir()
    {
        application?.changeWorkingDir()
    }
    
    @objc private func openMap()
    {
        application?.openMap()
    }
    
    @objc private func saveMap()
    {
        application?.saveMap()
    }
}

class DragDropView: MTKView
{
    var onDropFile: ((URL)->Void)?
    var url: URL?
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation
    {
        if let pathAlias = sender.draggingPasteboard.propertyList(forType: .fileURL) as? String
        {
            url = URL(fileURLWithPath: pathAlias).standardized
        }
        
        return .generic
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?)
    {
        url = nil
    }
    
//    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool
//    {
//
//    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool
    {
        return url != nil
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo)
    {
        if let url = self.url
        {
            NSApp.activate(ignoringOtherApps: true)
            onDropFile?(url)
        }
    }
}

let appDelegate = AppDelegate()
let application = NSApplication.shared
application.delegate = appDelegate
application.run()

