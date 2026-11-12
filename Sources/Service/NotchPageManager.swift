import SwiftUI
import AppKit

@MainActor
public final class NotchPageManager: ObservableObject {
    public static let shared = NotchPageManager()
    
    @Published public var activePageIndex: Int = 0
    
    // Swipe gesture accumulation & debounce
    private var accumulatedDeltaX: CGFloat = 0
    private var hasSwitchedInPhase: Bool = false
    private var lastSwitchTime: Date = .distantPast
    
    // Ambang batas swipe 2-jari trackpad (dalam points)
    private let swipeThreshold: CGFloat = 22.0
    
    private init() {}
    
    public var enabledCustomPages: [CustomNotchPage] {
        let pages = NotchSettingsStore.shared.preferences.enabledCustomPages
        return pages.isEmpty ? [NotchPreferences.defaultCustomPages[0]] : pages
    }
    
    public var currentCustomPage: CustomNotchPage {
        let pages = enabledCustomPages
        if activePageIndex >= 0 && activePageIndex < pages.count {
            return pages[activePageIndex]
        }
        return pages.first ?? NotchPreferences.defaultCustomPages[0]
    }
    
    /// Backward-compatible property mapping to legacy NotchPage
    public var activePage: NotchPage {
        switch currentCustomPage.primaryWidget {
        case .nowPlaying, .lyrics: return .dashboard
        case .shelf: return .dropZone
        case .clipboard: return .clipboard
        case .hardwareHUD: return .hardwareHUD
        case .quickTools: return .quickTools
        case .scratchpad: return .scratchpad
        case .camera: return .camera
        case .calendar: return .dashboard
        }
    }
    
    public var enabledPages: [NotchPage] {
        let pages = NotchSettingsStore.shared.preferences.enabledPages
        return pages.isEmpty ? [.dashboard] : pages
    }
    
    public func validateActivePage() {
        let count = enabledCustomPages.count
        if activePageIndex >= count {
            activePageIndex = max(0, count - 1)
        }
    }
    
    public func switchToPage(index: Int) {
        let count = enabledCustomPages.count
        guard index >= 0 && index < count && activePageIndex != index else { return }
        HapticService.shared.pageSwitch()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.80)) {
            activePageIndex = index
        }
    }
    
    public func switchToPage(id: String) {
        let pages = enabledCustomPages
        if let idx = pages.firstIndex(where: { $0.id == id }) {
            switchToPage(index: idx)
        }
    }
    
    public func switchToPage(_ page: NotchPage) {
        let pages = enabledCustomPages
        if let idx = pages.firstIndex(where: {
            switch $0.primaryWidget {
            case .nowPlaying, .lyrics: return page == .dashboard
            case .shelf: return page == .dropZone
            case .clipboard: return page == .clipboard
            case .hardwareHUD: return page == .hardwareHUD
            case .quickTools: return page == .quickTools
            case .scratchpad: return page == .scratchpad
            case .camera: return page == .camera
            case .calendar: return page == .dashboard
            }
        }) {
            switchToPage(index: idx)
        }
    }
    
    public func nextPage() {
        let count = enabledCustomPages.count
        guard count > 1 else { return }
        HapticService.shared.pageSwitch()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.80)) {
            activePageIndex = (activePageIndex + 1) % count
        }
    }
    
    public func previousPage() {
        let count = enabledCustomPages.count
        guard count > 1 else { return }
        HapticService.shared.pageSwitch()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.80)) {
            activePageIndex = (activePageIndex - 1 + count) % count
        }
    }
    
    public func togglePage() {
        nextPage()
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
        
        // 2. Pastikan gestur dominan horizontal (hindari konflik dengan scroll vertikal pada daftar)
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
            // Jari digeser dari kanan ke kiri (ke halaman berikutnya)
            if accumulatedDeltaX < -swipeThreshold {
                nextPage()
                lastSwitchTime = now
                hasSwitchedInPhase = true
                accumulatedDeltaX = 0
                return true
            }
            // Jari digeser dari kiri ke kanan (ke halaman sebelumnya)
            else if accumulatedDeltaX > swipeThreshold {
                previousPage()
                lastSwitchTime = now
                hasSwitchedInPhase = true
                accumulatedDeltaX = 0
                return true
            }
        }
        
        return true
    }
    
    /// Menangani gesture swipe 3-jari native macOS
    public func handleSwipe(event: NSEvent) -> Bool {
        if event.deltaX < 0 {
            nextPage()
            return true
        } else if event.deltaX > 0 {
            previousPage()
            return true
        }
        return false
    }
}

// MARK: - Native macOS Trackpad Haptic Feedback

public final class HapticService {
    public static let shared = HapticService()
    
    private init() {}
    
    /// Haptic klik ringan untuk tombol, toggle, dan kontrol media
    public func click() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .generic,
            performanceTime: .default
        )
    }
    
    /// Haptic tactile snap saat swipe perpindahan halaman notch atau snap slider
    public func pageSwitch() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .alignment,
            performanceTime: .default
        )
    }
    
    /// Haptic konfirmasi aksi sukses (copy clipboard, foto tertangkap, file masuk stash)
    public func success() {
        NSHapticFeedbackManager.defaultPerformer.perform(
            .alignment,
            performanceTime: .now
        )
    }
}
