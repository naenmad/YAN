import Foundation
import SwiftUI

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
    public var multiMonitorEnabled: Bool = false
    
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
            self.preferences = decoded
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
