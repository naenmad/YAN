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

public enum NormalStateMediaDisplay: String, Codable, CaseIterable, Identifiable {
    case songTitle = "title"
    case lyrics = "lyrics"
    case empty = "empty"
    
    public var id: String { rawValue }
    
    public var label: String {
        switch self {
        case .songTitle: return "Song Title"
        case .lyrics: return "Live Lyrics"
        case .empty: return "Empty (Minimal)"
        }
    }
}

public enum NotchPage: String, Codable, CaseIterable, Identifiable {
    case dashboard = "dashboard"
    case dropZone = "dropZone"
    case clipboard = "clipboard"
    case hardwareHUD = "hardwareHUD"
    case quickTools = "quickTools"
    case scratchpad = "scratchpad"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .dropZone: return "Drop Zone"
        case .clipboard: return "Clipboard"
        case .hardwareHUD: return "Hardware HUD"
        case .quickTools: return "Quick Tools"
        case .scratchpad: return "Scratchpad"
        }
    }
    
    public var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .dropZone: return "tray.and.arrow.down.fill"
        case .clipboard: return "doc.on.clipboard.fill"
        case .hardwareHUD: return "cpu"
        case .quickTools: return "slider.horizontal.3"
        case .scratchpad: return "note.text"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .dashboard: return "Media playback with synced lyrics & week calendar"
        case .dropZone: return "Native AirDrop target & temporary stash shelf"
        case .clipboard: return "Clipboard history & pinned snippets manager"
        case .hardwareHUD: return "Apple Silicon compute load, RAM & battery status"
        case .quickTools: return "Sleep guard, mic privacy, color picker & screen snip"
        case .scratchpad: return "Instant scratchpad thoughts & daily to-do checklist"
        }
    }
}

public struct NotchPageConfig: Codable, Identifiable, Equatable {
    public var id: String { page.rawValue }
    public var page: NotchPage
    public var isEnabled: Bool
    
    public init(page: NotchPage, isEnabled: Bool = true) {
        self.page = page
        self.isEnabled = isEnabled
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
    
    public var showOutline: Bool = true
    public var outlineOpacity: Double = 0.12 // Sangat halus (hint doang: 12% opacity, hairline 0.5pt)
    
    public var expandOnHover: Bool = true
    public var expandOnClick: Bool = true
    public var lockHeightOnHover: Bool = false
    public var hoverScaleWidth: Double = 1.25
    public var hoverScaleHeight: Double = 1.15
    
    // Dimensi Eksplisit untuk Mode Hover & Mode Clicked
    public var hoverWidth: Double = 500.0
    public var hoverHeight: Double = 56.0
    public var clickedWidth: Double = 580.0
    public var clickedHeight: Double = 152.0
    
    public var showInFullScreen: Bool = true
    public var displayTarget: DisplayTarget = .builtIn
    public var normalStateMediaDisplay: NormalStateMediaDisplay = .songTitle
    
    // Konfigurasi Halaman Notch (Dapat diaktifkan/dinonaktifkan & diatur urutannya)
    public static let defaultPagesOrder: [NotchPageConfig] = [
        NotchPageConfig(page: .dashboard, isEnabled: true),
        NotchPageConfig(page: .dropZone, isEnabled: true),
        NotchPageConfig(page: .clipboard, isEnabled: true),
        NotchPageConfig(page: .hardwareHUD, isEnabled: true),
        NotchPageConfig(page: .quickTools, isEnabled: true),
        NotchPageConfig(page: .scratchpad, isEnabled: true)
    ]
    
    public var pagesOrder: [NotchPageConfig] = NotchPreferences.defaultPagesOrder
    
    public var enabledPages: [NotchPage] {
        let active = pagesOrder.filter { $0.isEnabled }.map { $0.page }
        return active.isEmpty ? [.dashboard] : active
    }
    
    public static let `default` = NotchPreferences()
    
    enum CodingKeys: String, CodingKey {
        case widthPreset, heightPreset, notchStyle
        case width, height, cornerRadius, earRadius
        case showOutline, outlineOpacity
        case expandOnHover, expandOnClick, lockHeightOnHover
        case hoverScaleWidth, hoverScaleHeight
        case hoverWidth, hoverHeight, clickedWidth, clickedHeight
        case showInFullScreen, displayTarget
        case normalStateMediaDisplay
        case pagesOrder
    }
    
    public init() {}
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        widthPreset = try c.decodeIfPresent(WidthPreset.self, forKey: .widthPreset) ?? .standard
        heightPreset = try c.decodeIfPresent(HeightPreset.self, forKey: .heightPreset) ?? .menuBar
        notchStyle = try c.decodeIfPresent(NotchStyle.self, forKey: .notchStyle) ?? .apple
        width = try c.decodeIfPresent(Double.self, forKey: .width) ?? 200.0
        height = try c.decodeIfPresent(Double.self, forKey: .height) ?? 30.0
        cornerRadius = try c.decodeIfPresent(Double.self, forKey: .cornerRadius) ?? 14.0
        earRadius = try c.decodeIfPresent(Double.self, forKey: .earRadius) ?? 6.0
        showOutline = try c.decodeIfPresent(Bool.self, forKey: .showOutline) ?? true
        outlineOpacity = try c.decodeIfPresent(Double.self, forKey: .outlineOpacity) ?? 0.12
        expandOnHover = try c.decodeIfPresent(Bool.self, forKey: .expandOnHover) ?? true
        expandOnClick = try c.decodeIfPresent(Bool.self, forKey: .expandOnClick) ?? true
        lockHeightOnHover = try c.decodeIfPresent(Bool.self, forKey: .lockHeightOnHover) ?? false
        hoverScaleWidth = try c.decodeIfPresent(Double.self, forKey: .hoverScaleWidth) ?? 1.25
        hoverScaleHeight = try c.decodeIfPresent(Double.self, forKey: .hoverScaleHeight) ?? 1.15
        hoverWidth = try c.decodeIfPresent(Double.self, forKey: .hoverWidth) ?? 500.0
        hoverHeight = try c.decodeIfPresent(Double.self, forKey: .hoverHeight) ?? 56.0
        clickedWidth = try c.decodeIfPresent(Double.self, forKey: .clickedWidth) ?? 580.0
        clickedHeight = try c.decodeIfPresent(Double.self, forKey: .clickedHeight) ?? 152.0
        showInFullScreen = try c.decodeIfPresent(Bool.self, forKey: .showInFullScreen) ?? true
        displayTarget = try c.decodeIfPresent(DisplayTarget.self, forKey: .displayTarget) ?? .builtIn
        normalStateMediaDisplay = try c.decodeIfPresent(NormalStateMediaDisplay.self, forKey: .normalStateMediaDisplay) ?? .songTitle
        
        let decodedPages = try c.decodeIfPresent([NotchPageConfig].self, forKey: .pagesOrder)
        if let decoded = decodedPages, !decoded.isEmpty {
            // Pastikan semua jenis halaman terbaru masuk jika ada penambahan baru
            var current = decoded
            for page in NotchPage.allCases {
                if !current.contains(where: { $0.page == page }) {
                    current.append(NotchPageConfig(page: page, isEnabled: true))
                }
            }
            self.pagesOrder = current
        } else {
            self.pagesOrder = [
                NotchPageConfig(page: .dashboard, isEnabled: true),
                NotchPageConfig(page: .dropZone, isEnabled: true),
                NotchPageConfig(page: .clipboard, isEnabled: true),
                NotchPageConfig(page: .hardwareHUD, isEnabled: true),
                NotchPageConfig(page: .quickTools, isEnabled: true),
                NotchPageConfig(page: .scratchpad, isEnabled: true)
            ]
        }
    }
    
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
            // Pastikan opacity outline default halus (hint) jika belum tersetel
            if loaded.outlineOpacity == 0 || loaded.outlineOpacity > 0.20 {
                loaded.outlineOpacity = 0.12
            }
            if loaded.hoverWidth < 300 || loaded.hoverWidth > 800 { loaded.hoverWidth = 500.0 }
            if loaded.hoverHeight < 30 || loaded.hoverHeight > 120 { loaded.hoverHeight = 56.0 }
            if loaded.clickedWidth < 400 || loaded.clickedWidth > 900 { loaded.clickedWidth = 580.0 }
            if loaded.clickedHeight < 100 || loaded.clickedHeight > 300 { loaded.clickedHeight = 152.0 }
            loaded.expandOnClick = true
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
