import Foundation
import SwiftUI

public enum HeightPreset: String, Codable, CaseIterable, Identifiable {
    case compact = "compact"
    case menuBar = "menubar"
    case tall = "tall"
    case custom = "custom"
    
    public var id: String { rawValue }
    
    public var label: String {
        switch self {
        case .compact: return "Compact (26)"
        case .menuBar: return "Menu Bar (30)"
        case .tall: return "Tall (36)"
        case .custom: return "Custom"
        }
    }
    
    public var value: Double {
        switch self {
        case .compact: return 26.0
        case .menuBar: return 30.0
        case .tall: return 36.0
        case .custom: return 30.0
        }
    }
}

public enum WidthPreset: String, Codable, CaseIterable, Identifiable {
    case compact = "compact"
    case standard = "standard"
    case wide = "wide"
    case custom = "custom"
    
    public var id: String { rawValue }
    
    public var label: String {
        switch self {
        case .compact: return "Compact (160)"
        case .standard: return "Standard (200)"
        case .wide: return "Wide (260)"
        case .custom: return "Custom"
        }
    }
    
    public var value: Double {
        switch self {
        case .compact: return 160.0
        case .standard: return 200.0
        case .wide: return 260.0
        case .custom: return 200.0
        }
    }
}

public enum NotchStyle: String, Codable, CaseIterable, Identifiable {
    case apple = "apple"
    case capsule = "capsule"
    case subtle = "subtle"
    
    public var id: String { rawValue }
    
    public var label: String {
        switch self {
        case .apple: return "Apple Notch"
        case .capsule: return "Capsule"
        case .subtle: return "Subtle"
        }
    }
}

public enum DisplayTarget: String, Codable, CaseIterable, Identifiable {
    case builtIn = "builtin"
    case all = "all"
    case external = "external"
    
    public var id: String { rawValue }
    
    public var label: String {
        switch self {
        case .builtIn: return "MacBook Built-in Display"
        case .all: return "All Displays"
        case .external: return "External Display"
        }
    }
}

public struct NotchPreferences: Codable, Equatable {
    public var widthPreset: WidthPreset = .standard
    public var heightPreset: HeightPreset = .menuBar
    public var notchStyle: NotchStyle = .apple
    
    public var width: Double = 200.0
    public var height: Double = 30.0
    public var cornerRadius: Double = 14.0
    public var earRadius: Double = 6.0
    
    public var showOutline: Bool = true // Outline border to stay visible on black full-screen menu bars
    public var expandOnHover: Bool = true
    public var expandOnClick: Bool = false
    public var lockHeightOnHover: Bool = false // Locks height to menu bar, expands only horizontally
    public var hoverScaleWidth: Double = 1.25
    public var hoverScaleHeight: Double = 1.15
    
    public var showInFullScreen: Bool = true
    public var displayTarget: DisplayTarget = .builtIn
    
    public static let `default` = NotchPreferences()
    
    public mutating func updateRadiiForCurrentStyle() {
        switch notchStyle {
        case .apple:
            self.cornerRadius = max(8.0, round(height * 0.45))
            self.earRadius = max(4.0, round(height * 0.20))
        case .capsule:
            self.cornerRadius = round(height * 0.48)
            self.earRadius = 0.0
        case .subtle:
            self.cornerRadius = 8.0
            self.earRadius = 0.0
        }
    }
}

@MainActor
public final class NotchSettingsStore: ObservableObject {
    public static let shared = NotchSettingsStore()
    
    private let defaultsKey = "com.yan.notchanothernotch.settings"
    
    @Published public var preferences: NotchPreferences {
        didSet {
            save()
        }
    }
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode(NotchPreferences.self, from: data) {
            var loaded = decoded
            if loaded.width < 140 {
                loaded.width = 200.0
            }
            if loaded.height < 24 {
                loaded.height = 30.0
            }
            if loaded.hoverScaleHeight > 1.25 {
                loaded.hoverScaleHeight = 1.15
            }
            loaded.updateRadiiForCurrentStyle()
            self.preferences = loaded
        } else {
            var initial = NotchPreferences.default
            initial.updateRadiiForCurrentStyle()
            self.preferences = initial
        }
    }
    
    public func applyHeightPreset(_ preset: HeightPreset) {
        preferences.heightPreset = preset
        if preset != .custom {
            preferences.height = preset.value
            preferences.updateRadiiForCurrentStyle()
        }
    }
    
    public func applyWidthPreset(_ preset: WidthPreset) {
        preferences.widthPreset = preset
        if preset != .custom {
            preferences.width = preset.value
        }
    }
    
    public func applyNotchStyle(_ style: NotchStyle) {
        preferences.notchStyle = style
        preferences.updateRadiiForCurrentStyle()
    }
    
    public func save() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: defaultsKey)
        }
    }
    
    public func resetToDefaults() {
        var def = NotchPreferences.default
        def.updateRadiiForCurrentStyle()
        self.preferences = def
    }
}
