import SwiftUI
import AppKit

public enum NotchPage: Int, CaseIterable, Identifiable {
    case dashboard = 0 // Media Player + Calendar & Schedule
    case dropZone = 1  // AirDrop Target + Temporary Stash Shelf
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .dropZone: return "Drop Zone"
        }
    }
    
    public var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .dropZone: return "tray.and.arrow.down.fill"
        }
    }
}

@MainActor
public final class NotchPageManager: ObservableObject {
    public static let shared = NotchPageManager()
    
    @Published public var activePage: NotchPage = .dashboard
    
    // Swipe gesture accumulation & debounce
    private var accumulatedDeltaX: CGFloat = 0
    private var hasSwitchedInPhase: Bool = false
    private var lastSwitchTime: Date = .distantPast
    
    // Ambang batas swipe 2-jari trackpad (dalam points)
    private let swipeThreshold: CGFloat = 22.0
    
    private init() {}
    
    public func switchToPage(_ page: NotchPage) {
        guard activePage != page else { return }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.80)) {
            activePage = page
        }
    }
    
    public func togglePage() {
        switchToPage(activePage == .dashboard ? .dropZone : .dashboard)
    }
    
    /// Menangani event scrollWheel trackpad untuk swipe 2-jari horizontal
    /// Mengembalikan true jika event dikonsumsi sebagai navigasi halaman
    public func handleScrollWheel(event: NSEvent) -> Bool {
        // 1. Abaikan momentum scrolling inersia (hanya respons saat jari menempel di trackpad)
        if !event.momentumPhase.isEmpty {
            return false
        }
        
        let deltaX = event.scrollingDeltaX
        let deltaY = event.scrollingDeltaY
        
        // 2. Pastikan gestur dominan horizontal (hindari konflik dengan scroll vertikal pada daftar shelf)
        guard abs(deltaX) > abs(deltaY) * 1.15 else {
            if abs(deltaY) > 5 {
                accumulatedDeltaX = 0
            }
            return false
        }
        
        // 3. Reset saat fase awal gestur
        if event.phase == .began {
            accumulatedDeltaX = 0
            hasSwitchedInPhase = false
        }
        
        // 4. Reset saat fase selesai atau dibatalkan
        if event.phase == .ended || event.phase == .cancelled {
            accumulatedDeltaX = 0
            hasSwitchedInPhase = false
            return false
        }
        
        // 5. Normalisasi arah terhadap Natural Scrolling vs Classic Scrolling
        let effectiveDeltaX = event.isDirectionInvertedFromDevice ? deltaX : -deltaX
        accumulatedDeltaX += effectiveDeltaX
        
        // 6. Debounce cooldown (0.35s)
        let now = Date()
        guard now.timeIntervalSince(lastSwitchTime) > 0.35 else {
            return true
        }
        
        if !hasSwitchedInPhase {
            // Jari digeser dari kanan ke kiri (ke arah halaman berikutnya: Drop Zone)
            if accumulatedDeltaX < -swipeThreshold {
                if activePage != .dropZone {
                    switchToPage(.dropZone)
                    lastSwitchTime = now
                    hasSwitchedInPhase = true
                    accumulatedDeltaX = 0
                    return true
                }
            }
            // Jari digeser dari kiri ke kanan (ke arah halaman sebelumnya: Dashboard)
            else if accumulatedDeltaX > swipeThreshold {
                if activePage != .dashboard {
                    switchToPage(.dashboard)
                    lastSwitchTime = now
                    hasSwitchedInPhase = true
                    accumulatedDeltaX = 0
                    return true
                }
            }
        }
        
        return true
    }
    
    /// Menangani gesture swipe 3-jari native macOS
    public func handleSwipe(event: NSEvent) -> Bool {
        if event.deltaX < 0 {
            switchToPage(.dropZone)
            return true
        } else if event.deltaX > 0 {
            switchToPage(.dashboard)
            return true
        }
        return false
    }
}
