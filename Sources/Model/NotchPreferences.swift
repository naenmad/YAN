import Foundation
import SwiftUI

public enum DisplayTarget: String, Codable, CaseIterable, Identifiable {
    case builtIn = "builtin"
    case all = "all"
    case external = "external"
    
    public var id: String { rawValue }
    
    public var label: String {
        switch self {
        case .builtIn: return "Layar Bawaan MacBook"
        case .all: return "Semua Layar"
        case .external: return "Monitor Eksternal"
        }
    }
}

public struct NotchPreferences: Codable, Equatable {
    public var width: Double = 180.0
    public var height: Double = 32.0
    public var cornerRadius: Double = 14.0
    public var earRadius: Double = 6.0
    
    public var expandOnHover: Bool = true
    public var expandOnClick: Bool = false
    public var hoverScaleWidth: Double = 1.35
    public var hoverScaleHeight: Double = 1.50
    
    public var showInFullScreen: Bool = true
    public var displayTarget: DisplayTarget = .builtIn
    
    public static let `default` = NotchPreferences()
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
                loaded.width = 180.0
            }
            self.preferences = loaded
        } else {
            self.preferences = .default
        }
    }
    
    public func save() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: defaultsKey)
        }
    }
    
    public func resetToDefaults() {
        self.preferences = .default
    }
}
