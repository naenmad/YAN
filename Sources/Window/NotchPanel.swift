import AppKit
import SwiftUI

@MainActor
public final class NotchPanel: NSPanel {
    private var targetScreen: NSScreen
    private var currentSize: CGSize
    
    public init(screen: NSScreen) {
        self.targetScreen = screen
        let store = NotchSettingsStore.shared
        self.currentSize = CGSize(width: store.preferences.width, height: store.preferences.height)
        
        let screenFrame = screen.frame
        let initialRect = NSRect(
            x: screenFrame.origin.x + (screenFrame.width - currentSize.width) / 2,
            y: screenFrame.origin.y + screenFrame.height - currentSize.height,
            width: currentSize.width,
            height: currentSize.height
        )
        
        super.init(
            contentRect: initialRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .mainMenu + 1
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.isMovable = false
        self.isMovableByWindowBackground = false
        self.hidesOnDeactivate = false
        
        setupContentView()
    }
    
    private func setupContentView() {
        let canvas = NotchCanvasView { [weak self] newSize in
            self?.updateFrame(size: newSize)
        }
        
        let hostingView = NSHostingView(rootView: canvas)
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        self.contentView = hostingView
    }
    
    public func updateFrame(size: CGSize? = nil) {
        if let size = size {
            self.currentSize = size
        }
        
        let screenFrame = targetScreen.frame
        let x = screenFrame.origin.x + (screenFrame.width - currentSize.width) / 2
        let y = screenFrame.origin.y + screenFrame.height - currentSize.height
        let newFrame = NSRect(x: x, y: y, width: currentSize.width, height: currentSize.height)
        
        self.setFrame(newFrame, display: true, animate: false)
    }
    
    public func setTargetScreen(_ screen: NSScreen) {
        self.targetScreen = screen
        updateFrame()
    }
}
