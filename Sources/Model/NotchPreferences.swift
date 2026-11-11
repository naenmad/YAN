import Foundation
import SwiftUI

public enum NotchThemeMode: String, Codable, CaseIterable, Identifiable {
    case classicBlack = "classicBlack"
    case liquidGlass = "liquidGlass"
    case clearGlass = "clearGlass"
    
    public var id: String { rawValue }
    
    public var label: String {
        switch self {
        case .classicBlack: return "Pitch Black"
        case .liquidGlass: return "Liquid Glass"
        case .clearGlass: return "Clear Glass"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .classicBlack:
            return "Solid black finish that blends seamlessly with the hardware notch."
        case .liquidGlass:
            return "Translucent frosted glass with liquid specular reflections and blur."
        case .clearGlass:
            return "Ultra-minimal transparent glass HUD with sleek perimeter framing."
        }
    }
    
    public var icon: String {
        switch self {
        case .classicBlack: return "circle.fill"
        case .liquidGlass: return "drop.fill"
        case .clearGlass: return "square.dashed"
        }
    }
}

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
    case camera = "camera"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .dropZone: return "Drop Zone"
        case .clipboard: return "Clipboard"
        case .hardwareHUD: return "Hardware HUD"
        case .quickTools: return "Quick Tools"
        case .scratchpad: return "Scratchpad"
        case .camera: return "Notch Mirror"
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
        case .camera: return "camera.fill"
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
        case .camera: return "Live FaceTime HD vanity mirror & selfie snapshot"
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

// MARK: - Modular Widget Architecture

public enum WidgetSize: String, Codable, CaseIterable, Identifiable {
    case small = "small"     // Compact glance / hover bar
    case medium = "medium"   // Dual-pod half stage (~260pt)
    case large = "large"     // Full single stage (100% width)
    
    public var id: String { rawValue }
    
    public var label: String {
        switch self {
        case .small: return "Small (Glance)"
        case .medium: return "Medium (Pod)"
        case .large: return "Large (Full)"
        }
    }
}

public enum NotchWidgetType: String, Codable, CaseIterable, Identifiable {
    case nowPlaying = "nowPlaying"
    case lyrics = "lyrics"
    case calendar = "calendar"
    case shelf = "shelf"
    case clipboard = "clipboard"
    case hardwareHUD = "hardwareHUD"
    case quickTools = "quickTools"
    case scratchpad = "scratchpad"
    case camera = "camera"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .nowPlaying: return "Music Player"
        case .lyrics: return "Live Lyrics"
        case .calendar: return "Calendar & Agenda"
        case .shelf: return "Drop & Shelf"
        case .clipboard: return "Clipboard History"
        case .hardwareHUD: return "Hardware HUD"
        case .quickTools: return "Quick Tools"
        case .scratchpad: return "Scratchpad"
        case .camera: return "Notch Mirror"
        }
    }
    
    public var icon: String {
        switch self {
        case .nowPlaying: return "music.note"
        case .lyrics: return "quote.bubble.fill"
        case .calendar: return "calendar"
        case .shelf: return "tray.and.arrow.down.fill"
        case .clipboard: return "doc.on.clipboard.fill"
        case .hardwareHUD: return "cpu"
        case .quickTools: return "slider.horizontal.3"
        case .scratchpad: return "note.text"
        case .camera: return "camera.fill"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .nowPlaying: return "Artwork, title, scrubber slider & controller"
        case .lyrics: return "Synced real-time karaoke teleprompter"
        case .calendar: return "Today events, agenda schedule & month view"
        case .shelf: return "AirDrop target & temporary file staging shelf"
        case .clipboard: return "Recent clipboard snippets & pinned items"
        case .hardwareHUD: return "Apple Silicon CPU, RAM & Battery status"
        case .quickTools: return "Sleep guard, mic toggle, color picker & snip"
        case .scratchpad: return "Quick thought notes & daily checklist tasks"
        case .camera: return "Live FaceTime HD vanity mirror & snapshot"
        }
    }
}

public enum PageLayoutType: String, Codable, CaseIterable, Identifiable {
    case dualPod = "dualPod"       // 2x + 2x (50% : 50%)
    case fullStage = "fullStage"   // 4x (100%)
    case trio = "trio"             // 1x + 1x + 2x (25% : 25% : 50%)
    case quad = "quad"             // 1x + 1x + 1x + 1x (25% : 25% : 25% : 25%)
    
    public var id: String { rawValue }
    
    public var label: String {
        switch self {
        case .dualPod: return "Dual-Pod (2x + 2x)"
        case .fullStage: return "Full Stage (4x)"
        case .trio: return "Trio (1x + 1x + 2x)"
        case .quad: return "Quad (4 × 1x)"
        }
    }
    
    public var icon: String {
        switch self {
        case .dualPod: return "rectangle.split.2x1"
        case .fullStage: return "rectangle.fill"
        case .trio: return "rectangle.split.3x1"
        case .quad: return "square.grid.2x2"
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "dualPod": self = .dualPod
        case "fullStage": self = .fullStage
        case "trio", "triplePod": self = .trio
        case "quad": self = .quad
        default: self = .dualPod
        }
    }
}

public struct CustomNotchPage: Codable, Identifiable, Equatable {
    public var id: String
    public var pageNumber: Int // Strictly 1, 2, 3, or 4
    public var name: String
    public var isEnabled: Bool
    public var layout: PageLayoutType
    public var slot1: NotchWidgetType
    public var slot2: NotchWidgetType?
    public var slot3: NotchWidgetType?
    public var slot4: NotchWidgetType?
    
    public init(
        id: String = UUID().uuidString,
        pageNumber: Int,
        name: String,
        isEnabled: Bool = true,
        layout: PageLayoutType = .dualPod,
        slot1: NotchWidgetType,
        slot2: NotchWidgetType? = nil,
        slot3: NotchWidgetType? = nil,
        slot4: NotchWidgetType? = nil
    ) {
        self.id = id
        self.pageNumber = pageNumber
        self.name = name
        self.isEnabled = isEnabled
        self.layout = layout
        self.slot1 = slot1
        self.slot2 = slot2
        self.slot3 = slot3
        self.slot4 = slot4
    }
    
    enum CodingKeys: String, CodingKey {
        case id, pageNumber, name, isEnabled, layout
        case slot1, slot2, slot3, slot4
        case primaryWidget, secondaryWidget, tertiaryWidget
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.pageNumber = try container.decodeIfPresent(Int.self, forKey: .pageNumber) ?? 1
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Page \(pageNumber)"
        self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        self.layout = try container.decodeIfPresent(PageLayoutType.self, forKey: .layout) ?? .dualPod
        
        self.slot1 = try container.decodeIfPresent(NotchWidgetType.self, forKey: .slot1)
            ?? container.decodeIfPresent(NotchWidgetType.self, forKey: .primaryWidget)
            ?? .nowPlaying
        self.slot2 = try container.decodeIfPresent(NotchWidgetType.self, forKey: .slot2)
            ?? container.decodeIfPresent(NotchWidgetType.self, forKey: .secondaryWidget)
        self.slot3 = try container.decodeIfPresent(NotchWidgetType.self, forKey: .slot3)
            ?? container.decodeIfPresent(NotchWidgetType.self, forKey: .tertiaryWidget)
        self.slot4 = try container.decodeIfPresent(NotchWidgetType.self, forKey: .slot4)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(pageNumber, forKey: .pageNumber)
        try container.encode(name, forKey: .name)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(layout, forKey: .layout)
        try container.encode(slot1, forKey: .slot1)
        try container.encodeIfPresent(slot2, forKey: .slot2)
        try container.encodeIfPresent(slot3, forKey: .slot3)
        try container.encodeIfPresent(slot4, forKey: .slot4)
    }
    
    // Compatibility accessors
    public var primaryWidget: NotchWidgetType {
        get { slot1 }
        set { slot1 = newValue }
    }
    public var secondaryWidget: NotchWidgetType? {
        get { slot2 }
        set { slot2 = newValue }
    }
    public var tertiaryWidget: NotchWidgetType? {
        get { slot3 }
        set { slot3 = newValue }
    }
}

public struct NotchPreferences: Codable, Equatable {
    public var themeMode: NotchThemeMode = .liquidGlass
    public var glassOpacity: Double = 0.75
    
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
    
    // Modular Custom Pages (Strictly Pages 1 to 4 with Modular Unit Box Layouts)
    public static let defaultCustomPages: [CustomNotchPage] = [
        CustomNotchPage(
            id: "page-1",
            pageNumber: 1,
            name: "Music & Lyrics",
            isEnabled: true,
            layout: .dualPod,
            slot1: .nowPlaying,
            slot2: .lyrics
        ),
        CustomNotchPage(
            id: "page-2",
            pageNumber: 2,
            name: "Drop & Clipboard",
            isEnabled: true,
            layout: .dualPod,
            slot1: .shelf,
            slot2: .clipboard
        ),
        CustomNotchPage(
            id: "page-3",
            pageNumber: 3,
            name: "System & Tools",
            isEnabled: true,
            layout: .dualPod,
            slot1: .hardwareHUD,
            slot2: .quickTools
        ),
        CustomNotchPage(
            id: "page-4",
            pageNumber: 4,
            name: "Notch Mirror",
            isEnabled: true,
            layout: .fullStage,
            slot1: .camera
        )
    ]
    
    public var customPages: [CustomNotchPage] = NotchPreferences.defaultCustomPages
    
    public var enabledCustomPages: [CustomNotchPage] {
        let active = customPages.filter { $0.isEnabled }
        return active.isEmpty ? [NotchPreferences.defaultCustomPages[0]] : active
    }
    
    // Konfigurasi Halaman Notch (Dapat diaktifkan/dinonaktifkan & diatur urutannya)
    public static let defaultPagesOrder: [NotchPageConfig] = [
        NotchPageConfig(page: .dashboard, isEnabled: true),
        NotchPageConfig(page: .dropZone, isEnabled: true),
        NotchPageConfig(page: .clipboard, isEnabled: true),
        NotchPageConfig(page: .hardwareHUD, isEnabled: true),
        NotchPageConfig(page: .quickTools, isEnabled: true),
        NotchPageConfig(page: .scratchpad, isEnabled: true),
        NotchPageConfig(page: .camera, isEnabled: true)
    ]
    
    public var pagesOrder: [NotchPageConfig] = NotchPreferences.defaultPagesOrder
    
    public var enabledPages: [NotchPage] {
        let active = pagesOrder.filter { $0.isEnabled }.map { $0.page }
        return active.isEmpty ? [.dashboard] : active
    }
    
    public static let `default` = NotchPreferences()
    
    enum CodingKeys: String, CodingKey {
        case themeMode, glassOpacity
        case widthPreset, heightPreset, notchStyle
        case width, height, cornerRadius, earRadius
        case showOutline, outlineOpacity
        case expandOnHover, expandOnClick, lockHeightOnHover
        case hoverScaleWidth, hoverScaleHeight
        case hoverWidth, hoverHeight, clickedWidth, clickedHeight
        case showInFullScreen, displayTarget
        case normalStateMediaDisplay
        case pagesOrder
        case customPages
    }
    
    public init() {}
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        themeMode = try c.decodeIfPresent(NotchThemeMode.self, forKey: .themeMode) ?? .liquidGlass
        glassOpacity = try c.decodeIfPresent(Double.self, forKey: .glassOpacity) ?? 0.75
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
                NotchPageConfig(page: .scratchpad, isEnabled: true),
                NotchPageConfig(page: .camera, isEnabled: true)
            ]
        }
        
        let decodedCustom = try c.decodeIfPresent([CustomNotchPage].self, forKey: .customPages)
        if let dec = decodedCustom, dec.count == 4 {
            var validated = dec
            for i in 0..<4 {
                validated[i].pageNumber = i + 1
            }
            validated[0].isEnabled = true
            self.customPages = validated
        } else {
            self.customPages = NotchPreferences.defaultCustomPages
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
            if loaded.outlineOpacity == 0 || loaded.outlineOpacity > 0.40 {
                loaded.outlineOpacity = 0.12
            }
            if loaded.glassOpacity < 0.20 || loaded.glassOpacity > 1.0 {
                loaded.glassOpacity = 0.75
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
