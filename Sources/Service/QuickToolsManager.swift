import Foundation
import AppKit
import SwiftUI
import IOKit.pwr_mgt

@MainActor
public final class QuickToolsManager: ObservableObject {
    public static let shared = QuickToolsManager()
    
    @Published public var isCaffeineActive: Bool = false
    @Published public var lastSampledHex: String? = nil
    @Published public var isMicMuted: Bool = false
    @Published public var toastMessage: String? = nil
    
    private var assertionID: IOPMAssertionID = 0
    
    private init() {
        checkMicMuteStatus()
    }
    
    // MARK: - Keep Awake (Caffeine)
    
    public func toggleCaffeine() {
        if isCaffeineActive {
            disableCaffeine()
        } else {
            enableCaffeine()
        }
    }
    
    private func enableCaffeine() {
        let reason = "YAN Keep Awake Active" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        if result == kIOReturnSuccess {
            self.isCaffeineActive = true
            showToast("Keep Awake Enabled")
        }
    }
    
    private func disableCaffeine() {
        if isCaffeineActive && assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
            self.isCaffeineActive = false
            showToast("Keep Awake Disabled")
        }
    }
    
    // MARK: - Color Eyedropper Sampler
    
    public func pickScreenColor() {
        if #available(macOS 10.15, *) {
            NSColorSampler().show { [weak self] nsColor in
                guard let color = nsColor else { return }
                guard let rgb = color.usingColorSpace(.sRGB) else { return }
                let r = Int(round(rgb.redComponent * 255))
                let g = Int(round(rgb.greenComponent * 255))
                let b = Int(round(rgb.blueComponent * 255))
                let hex = String(format: "#%02X%02X%02X", r, g, b)
                
                Task { @MainActor [weak self] in
                    self?.lastSampledHex = hex
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(hex, forType: .string)
                    self?.showToast("Copied \(hex)")
                }
            }
        }
    }
    
    // MARK: - Screen Capture to Clipboard
    
    public func triggerScreenCapture() {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            let task = Process()
            task.launchPath = "/usr/sbin/screencapture"
            task.arguments = ["-i", "-c"] // Interactive selection, copy to clipboard
            try? task.run()
            task.waitUntilExit()
            if task.terminationStatus == 0 {
                Task { @MainActor [weak self] in
                    self?.showToast("Screenshot Copied")
                }
            }
        }
    }
    
    // MARK: - Microphone Mute Toggle
    
    public func toggleMicMute() {
        let targetVolume = isMicMuted ? 75 : 0
        let script = "set volume input volume \(targetVolume)"
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if error == nil {
                self.isMicMuted.toggle()
                showToast(isMicMuted ? "Microphone Muted" : "Microphone Active")
            }
        }
    }
    
    private func checkMicMuteStatus() {
        let script = "input volume of (get volume settings)"
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let desc = scriptObject.executeAndReturnError(&error)
            if error == nil, let vol = desc.stringValue, let intVol = Int(vol) {
                self.isMicMuted = (intVol == 0)
            }
        }
    }
    
    // MARK: - Sound Preferences
    
    public func openSoundPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Sound-Settings.extension") {
            NSWorkspace.shared.open(url)
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Sound.prefPane"))
        }
    }
    
    // MARK: - Helper Toast
    
    private func showToast(_ message: String) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            self.toastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            if self.toastMessage == message {
                withAnimation { self.toastMessage = nil }
            }
        }
    }
}
