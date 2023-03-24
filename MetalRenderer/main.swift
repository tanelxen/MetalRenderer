//
//  main.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 23.03.2023.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate
{
    var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification)
    {
        let frame = CGRect(x: 0, y: 0, width: 640, height: 480) //NSScreen.main?.frame
        
        window = NSWindow(contentRect: frame,
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered,
                          defer: false)
        window?.title = "Metal Renderer"
        window?.center()
        
        window?.contentView = GameView()
        window?.makeKeyAndOrderFront(nil)
        
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

