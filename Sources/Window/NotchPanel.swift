import AppKit
import SwiftUI

/// Custom NSHostingView yang mengalirkan event klik/mouse di luar siluet notch ke aplikasi di bawahnya
final class NotchHostingView<Content: View>: NSHostingView<Content> {
    override func hitTest(_ point: NSPoint) -> NSView? {
        let store = NotchSettingsStore.shared
        let baseWidth = CGFloat(store.preferences.width)
        let baseHeight = CGFloat(store.preferences.height)
        
        // Bounding box maksimum untuk hit-testing (mencakup batas saat Media Pod + Calendar expanded)
        let maxActiveWidth = max(baseWidth * CGFloat(store.preferences.hoverScaleWidth) + 24, 560.0)
        let maxActiveHeight = max(baseHeight * CGFloat(store.preferences.hoverScaleHeight) + 16, 85.0)
        
        // Dalam koordinat AppKit view, y = bounds.height adalah bagian paling atas
        let notchRect = NSRect(
            x: (bounds.width - maxActiveWidth) / 2,
            y: bounds.height - maxActiveHeight,
            width: maxActiveWidth,
            height: maxActiveHeight
        )
        
        if notchRect.contains(point) {
            return super.hitTest(point)
        }
        
        // Di luar siluet notch, klik/scroll tembus ke jendela/menu bar di belakangnya
        return nil
    }
}

@MainActor
public final class NotchPanel: NSPanel {
    private var targetScreen: NSScreen
    
    // Dimensi kanvas jendela overlay yang luas agar animasi ekspansi leluasa tanpa resize window
    private let windowWidth: CGFloat = 580.0
    private let windowHeight: CGFloat = 160.0
    
    public init(screen: NSScreen) {
        self.targetScreen = screen
        
        let screenFrame = screen.frame
        let panelRect = NSRect(
            x: screenFrame.origin.x + (screenFrame.width - windowWidth) / 2,
            y: screenFrame.origin.y + screenFrame.height - windowHeight,
            width: windowWidth,
            height: windowHeight
        )
        
        super.init(
            contentRect: panelRect,
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
        let canvas = NotchCanvasView()
        let hostingView = NotchHostingView(rootView: canvas)
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        self.contentView = hostingView
    }
    
    public func updatePosition() {
        let screenFrame = targetScreen.frame
        let newRect = NSRect(
            x: screenFrame.origin.x + (screenFrame.width - windowWidth) / 2,
            y: screenFrame.origin.y + screenFrame.height - windowHeight,
            width: windowWidth,
            height: windowHeight
        )
        self.setFrame(newRect, display: true, animate: false)
    }
    
    public func setTargetScreen(_ screen: NSScreen) {
        self.targetScreen = screen
        updatePosition()
    }
}
