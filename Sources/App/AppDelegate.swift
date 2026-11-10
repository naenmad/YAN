import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Inisialisasi dan tampilkan Notch Overlay
        NotchWindowManager.shared.start()
        
        // 2. Daftarkan Global Hotkey (Cmd + Shift + ,)
        GlobalHotkeyManager.shared.registerDefaultShortcut()
        
        // 3. Tampilkan jendela pengaturan native macOS di main queue
        DispatchQueue.main.async {
            SettingsWindowController.shared.show()
        }
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Tetap berjalan di background saat window settings ditutup
    }
}
