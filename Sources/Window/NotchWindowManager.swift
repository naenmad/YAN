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
    
    private func resolveTargetScreens() -> [NSScreen] {
        let store = NotchSettingsStore.shared
        let allScreens = NSScreen.screens
        
        guard !allScreens.isEmpty else { return [] }
        
        // Cari MacBook Built-in Display (layar bawaan MacBook Air)
        let builtInScreen = allScreens.first(where: {
            $0.localizedName.localizedCaseInsensitiveContains("built-in") ||
            ($0.frame.origin.x == 0 && $0.frame.origin.y == 0)
        }) ?? allScreens.first!
        
        switch store.preferences.displayTarget {
        case .builtIn:
            return [builtInScreen]
            
        case .external:
            let externals = allScreens.filter { $0 != builtInScreen }
            return externals.isEmpty ? [builtInScreen] : externals
            
        case .all:
            return allScreens
        }
    }
    
    public func refreshPanels() {
        for panel in panels {
            panel.orderOut(nil)
        }
        panels.removeAll()
        
        let targetScreens = resolveTargetScreens()
        for screen in targetScreens {
            let panel = NotchPanel(screen: screen)
            panel.orderFrontRegardless()
            panels.append(panel)
        }
    }
    
    public func updateAllPanels() {
        let targetScreens = resolveTargetScreens()
        
        if targetScreens.count != panels.count {
            refreshPanels()
            return
        }
        
        for (index, panel) in panels.enumerated() {
            if index < targetScreens.count {
                panel.setTargetScreen(targetScreens[index])
            }
        }
    }
}
