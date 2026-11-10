import AppKit
import SwiftUI

@MainActor
public final class SettingsWindowController: NSObject, NSWindowDelegate {
    public static let shared = SettingsWindowController()
    
    private var window: NSWindow?
    
    private override init() {
        super.init()
    }
    
    public func show() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView()
        let hostingView = NSHostingView(rootView: settingsView)
        
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        newWindow.title = "YAN Settings"
        newWindow.contentView = hostingView
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        
        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    public func close() {
        window?.orderOut(nil)
    }
    
    public func windowWillClose(_ notification: Notification) {
        // window is kept alive for quick re-opening
    }
}
