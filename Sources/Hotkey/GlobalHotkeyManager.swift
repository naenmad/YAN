import AppKit
import Carbon

@MainActor
public final class GlobalHotkeyManager {
    public static let shared = GlobalHotkeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    private init() {}
    
    public func registerDefaultShortcut() {
        // Shortcut: Command + Shift + Comma (,) -> 43
        let hotKeyID = EventHotKeyID(signature: OSType(0x59414E31), id: 1) // 'YAN1'
        let modifiers = UInt32(cmdKey | shiftKey)
        let keyCode = UInt32(kVK_ANSI_Comma)
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                Task { @MainActor in
                    SettingsWindowController.shared.show()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )
        
        if status == noErr {
            RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        }
    }
}
