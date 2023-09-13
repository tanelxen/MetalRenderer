//
//  main.swift
//  MetalRenderer
//
//  Created by Fedor Artemenkov on 23.03.2023.
//

import Cocoa
import MetalKit

class AppDelegate: NSObject, NSApplicationDelegate
{
    var window: NSWindow?
    var vc: NSViewController?

    func applicationDidFinishLaunching(_ notification: Notification)
    {
        let frame = NSScreen.main!.frame
        
        window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: frame.width, height: frame.height),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered,
                          defer: false)
        window?.title = "Game"
        window?.center()
        
        vc = MenuViewController()
        
        window?.contentView = vc?.view
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

