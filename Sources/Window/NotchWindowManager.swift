import AppKit
import Combine

@MainActor
public final class NotchWindowManager {
    public static let shared = NotchWindowManager()
    
    private var panels: [NotchPanel] = []
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupObservers()
    }
    
    public func start() {
        refreshPanels()
    }
    
    private func setupObservers() {
        // Pantau perubahan resolusi layar atau sambungan monitor
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.refreshPanels()
                }
            }
            .store(in: &cancellables)
        
        // Pantau perubahan preferensi pengguna
        NotchSettingsStore.shared.$preferences
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateAllPanels()
                }
            }
            .store(in: &cancellables)
    }
    
    public func refreshPanels() {
        // Tutup panel yang sudah ada
        for panel in panels {
            panel.orderOut(nil)
        }
        panels.removeAll()
        
        let store = NotchSettingsStore.shared
        let screens = store.preferences.multiMonitorEnabled ? NSScreen.screens : [NSScreen.main].compactMap { $0 }
        
        for screen in screens {
            let panel = NotchPanel(screen: screen)
            panel.orderFrontRegardless()
            panels.append(panel)
        }
    }
    
    public func updateAllPanels() {
        let store = NotchSettingsStore.shared
        let screens = store.preferences.multiMonitorEnabled ? NSScreen.screens : [NSScreen.main].compactMap { $0 }
        
        if screens.count != panels.count {
            refreshPanels()
            return
        }
        
        for (index, panel) in panels.enumerated() {
            if index < screens.count {
                panel.setTargetScreen(screens[index])
            }
        }
    }
}
