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

