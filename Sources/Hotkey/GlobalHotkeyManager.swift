import AppKit
import Carbon

extension Notification.Name {
    public static let toggleNotchExpansion = Notification.Name("com.yan.notchanothernotch.toggleExpansion")
}

@MainActor
public final class GlobalHotkeyManager {
    public static let shared = GlobalHotkeyManager()
    
    private var hotKeyRef1: EventHotKeyRef?
    private var hotKeyRef2: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    private init() {}
    
    public func registerDefaultShortcut() {
        // HotKey 1: Command + Shift + Comma (,) -> Open Settings
        let hotKeyID1 = EventHotKeyID(signature: OSType(0x59414E31), id: 1) // 'YAN1'
        let modifiers = UInt32(cmdKey | shiftKey)
        let commaKeyCode = UInt32(kVK_ANSI_Comma)
        
        // HotKey 2: Command + Shift + N -> Toggle Notch Dropdown HUD
        let hotKeyID2 = EventHotKeyID(signature: OSType(0x59414E32), id: 2) // 'YAN2'
        let nKeyCode = UInt32(kVK_ANSI_N)
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                guard let event = event else { return noErr }
                var hkID = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hkID)
                
                Task { @MainActor in
                    if hkID.id == 1 {
                        SettingsWindowController.shared.show()
                    } else if hkID.id == 2 {
                        NotificationCenter.default.post(name: .toggleNotchExpansion, object: nil)
                    }
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )
        
        if status == noErr {
            RegisterEventHotKey(commaKeyCode, modifiers, hotKeyID1, GetApplicationEventTarget(), 0, &hotKeyRef1)
            RegisterEventHotKey(nKeyCode, modifiers, hotKeyID2, GetApplicationEventTarget(), 0, &hotKeyRef2)
        }
    }
}
