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
        
        let view = MTKView()
        application = SandboxApplication(view: view)
        
        window?.contentView = view
        window?.makeKeyAndOrderFront(nil)
        window?.acceptsMouseMovedEvents = true
        
#if DEBUG
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
#endif
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

let appDelegate = AppDelegate()
let application = NSApplication.shared
application.delegate = appDelegate
application.run()

