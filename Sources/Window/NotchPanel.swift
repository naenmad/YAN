import AppKit
import SwiftUI

/// Custom NSHostingView yang mengalirkan event klik/mouse di luar siluet notch ke aplikasi di bawahnya
final class NotchHostingView<Content: View>: NSHostingView<Content> {
    override func hitTest(_ point: NSPoint) -> NSView? {
        let store = NotchSettingsStore.shared
        let baseWidth = CGFloat(store.preferences.width)
        let baseHeight = CGFloat(store.preferences.height)
        
        // Bounding box maksimum untuk hit-testing (mencakup batas saat Media Pod + Calendar + Jadwal expanded)
        let maxActiveWidth = max(
            CGFloat(store.preferences.clickedWidth) + 32,
            CGFloat(store.preferences.hoverWidth) + 32,
            baseWidth + 32,
            600.0
        )
        let maxActiveHeight = max(
            CGFloat(store.preferences.clickedHeight) + 24,
            CGFloat(store.preferences.hoverHeight) + 24,
            baseHeight + 24,
            160.0
        )
        
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
    
    override func scrollWheel(with event: NSEvent) {
        // Tangani gestur swipe 2-jari trackpad untuk berganti halaman (Dashboard <-> Drop Zone)
        if NotchPageManager.shared.handleScrollWheel(event: event) {
            return
        }
        super.scrollWheel(with: event)
    }
    
    override func swipe(with event: NSEvent) {
        // Tangani gestur swipe native 3-jari jika diaktifkan di macOS
        if NotchPageManager.shared.handleSwipe(event: event) {
            return
        }
        super.swipe(with: event)
    }
}

@MainActor
public final class NotchPanel: NSPanel {
    private var targetScreen: NSScreen
    
    // Dimensi kanvas jendela overlay yang luas (850x260) agar animasi ekspansi leluasa tanpa resize window
    private let windowWidth: CGFloat = 850.0
    private let windowHeight: CGFloat = 260.0
    
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
