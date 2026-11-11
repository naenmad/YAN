import SwiftUI
import AppKit
import UniformTypeIdentifiers

public enum SettingsCategory: String, CaseIterable, Identifiable {
    case appearance = "Appearance"
    case pages = "Pages & Widgets"
    case behavior = "Behavior"
    case displays = "Displays"
    case about = "About"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .appearance: return "paintpalette.fill"
        case .pages: return "square.grid.2x2.fill"
        case .behavior: return "hand.tap.fill"
        case .displays: return "display.2"
        case .about: return "info.circle.fill"
        }
    }
}

public struct SettingsView: View {
    @ObservedObject var store: NotchSettingsStore = .shared
    @State private var selectedCategory: SettingsCategory = .pages
    
    public var body: some View {
        HStack(spacing: 0) {
            // MARK: - 1. Fixed Unbreakable Sidebar
            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 16)
                    .padding(.bottom, 6)
                
                ForEach(SettingsCategory.allCases) { category in
                    SidebarItemButton(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .frame(width: 200)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.55))
            
            Divider()
            
            // MARK: - 2. Detail Content Pane
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedCategory {
                    case .appearance:
                        AppearanceCategoryView(store: store)
                    case .behavior:
                        BehaviorCategoryView(store: store)
                    case .pages:
                        PagesCategoryView(store: store)
                    case .displays:
                        DisplayCategoryView(store: store)
                    case .about:
                        AboutCategoryView(store: store)
                    }
                }
                .padding(26)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 780, idealWidth: 860, minHeight: 560, idealHeight: 640)
    }
}

// MARK: - Sidebar Item Component

private struct SidebarItemButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 20)
                    .foregroundColor(isSelected ? .white : .accentColor)
                
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Appearance Category View

private struct AppearanceCategoryView: View {
    @ObservedObject var store: NotchSettingsStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Appearance & Theme")
                    .font(.title2.weight(.semibold))
                Text("Choose your visual style, glass translucency, resting notch dimensions, and curvature.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 1. Visual Theme Style Selector (Pitch Black / Liquid Glass / Clear Glass)
            GroupBox(label: Text("Theme Style").font(.subheadline.weight(.semibold))) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        ForEach(NotchThemeMode.allCases) { mode in
                            themeCard(for: mode)
                        }
                    }
                    
                    // Glass Opacity Slider if Glass Mode active
                    if store.preferences.themeMode != .classicBlack {
                        Divider()
                            .padding(.vertical, 2)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Glass Tint Density")
                                        .fontWeight(.medium)
                                        .font(.subheadline)
                                    Text("Balances background frosted blur and deep contrast for text.")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("\(Int(store.preferences.glassOpacity * 100))%")
                                    .font(.footnote.monospacedDigit())
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $store.preferences.glassOpacity, in: 0.25...0.95, step: 0.05)
                        }
                    }
                }
                .padding(14)
            }
            
            // 2. Resting Notch Height
            GroupBox(label: Text("Resting Height").font(.subheadline.weight(.semibold))) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Menu Bar Alignment")
                                .fontWeight(.medium)
                            Text("The 'Menu Bar (30)' option aligns flush with standard Apple Silicon menu bars.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(Int(store.preferences.height)) pt")
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("", selection: Binding(
                        get: { store.preferences.heightPreset },
                        set: { store.applyHeightPreset($0) }
                    )) {
                        Text("Compact (26)").tag(HeightPreset.compact)
                        Text("Menu Bar (30)").tag(HeightPreset.menuBar)
                        Text("Tall (36)").tag(HeightPreset.tall)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
                .padding(14)
            }
            
            // 3. Resting Notch Width
            GroupBox(label: Text("Resting Width").font(.subheadline.weight(.semibold))) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Default Horizontal Width")
                                .fontWeight(.medium)
                            Text("Choose a preset width or drag the slider for custom sizing.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(Int(store.preferences.width)) pt")
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("", selection: Binding(
                        get: { store.preferences.widthPreset },
                        set: { store.applyWidthPreset($0) }
                    )) {
                        Text("Compact (160)").tag(WidthPreset.compact)
                        Text("Standard (200)").tag(WidthPreset.standard)
                        Text("Wide (260)").tag(WidthPreset.wide)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    
                    Slider(value: Binding(
                        get: { store.preferences.width },
                        set: {
                            store.preferences.width = $0
                            store.preferences.widthPreset = .custom
                        }
                    ), in: 140...320, step: 2)
                    .padding(.top, 4)
                }
                .padding(14)
            }
            
            // 4. Corner Style
            GroupBox(label: Text("Corner Curvature").font(.subheadline.weight(.semibold))) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Corner Radii Proportions")
                            .fontWeight(.medium)
                        Text("Corner and ear radii automatically proportion to the notch height.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("", selection: Binding(
                        get: { store.preferences.notchStyle },
                        set: { store.applyNotchStyle($0) }
                    )) {
                        ForEach(NotchStyle.allCases) { style in
                            Text(style.label).tag(style)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
                .padding(14)
            }
            
            // 5. Subtle Perimeter Border & Specular Rim
            GroupBox(label: Text("Perimeter Specular Rim").font(.subheadline.weight(.semibold))) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Show Specular Rim Outline", isOn: $store.preferences.showOutline)
                        .fontWeight(.medium)
                    
                    Text("Adds a razor-thin specular highlight so the notch silhouette is gently perceptible against pitch-black backgrounds or wallpapers.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    if store.preferences.showOutline {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Rim Opacity")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(store.preferences.outlineOpacity * 100))%")
                                    .font(.footnote.monospacedDigit())
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $store.preferences.outlineOpacity, in: 0.04...0.40, step: 0.02)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(14)
            }
        }
    }
    
    @ViewBuilder
    private func themeCard(for mode: NotchThemeMode) -> some View {
        let isSelected = store.preferences.themeMode == mode
        
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                store.preferences.themeMode = mode
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Theme visual badge / preview
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(previewBackground(for: mode))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(previewBorder(for: mode), lineWidth: 1)
                        )
                    
                    HStack(spacing: 5) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(mode == .liquidGlass ? .cyan : (mode == .clearGlass ? .white : .white.opacity(0.7)))
                        
                        Text(mode.label)
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .frame(height: 48)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(mode.label)
                            .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 14))
                        }
                    }
                    
                    Text(mode.subtitle)
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.10) : Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.gray.opacity(0.20), lineWidth: isSelected ? 1.8 : 0.8)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func previewBackground(for mode: NotchThemeMode) -> AnyShapeStyle {
        switch mode {
        case .classicBlack:
            return AnyShapeStyle(Color.black)
        case .liquidGlass:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.cyan.opacity(0.25),
                        Color(white: 0.15).opacity(0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .clearGlass:
            return AnyShapeStyle(Color.white.opacity(0.08))
        }
    }
    
    private func previewBorder(for mode: NotchThemeMode) -> Color {
        switch mode {
        case .classicBlack:
            return Color.white.opacity(0.15)
        case .liquidGlass:
            return Color.cyan.opacity(0.50)
        case .clearGlass:
            return Color.white.opacity(0.40)
        }
    }
}

// MARK: - Behavior Category View

private struct BehaviorCategoryView: View {
    @ObservedObject var store: NotchSettingsStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Behavior & Interactions")
                    .font(.title2.weight(.semibold))
                Text("Configure expansion triggers, resting state glance, and adaptive window dimensions.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 1. Triggers
            GroupBox(label: Text("Expansion Triggers").font(.subheadline.weight(.semibold))) {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle("Expand on Mouse Hover", isOn: $store.preferences.expandOnHover)
                        .fontWeight(.medium)
                    
                    Text("Smoothly expands to the preview bar when the pointer moves over the notch.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Toggle("Lock Height on Hover (Expand Horizontally Only)", isOn: $store.preferences.lockHeightOnHover)
                        .fontWeight(.medium)
                    
                    Text("Keeps height strictly locked to menu bar height (30 pt) so it never drops down or covers content on full-screen pages.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Toggle("Expand on Click", isOn: $store.preferences.expandOnClick)
                        .fontWeight(.medium)
                    
                    Text("Keeps the notch in expanded dashboard mode until clicked again or clicked outside.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(14)
            }
            
            // 2. Normal State (Resting) Media Display
            GroupBox(label: Text("Normal State (Resting) Media Display").font(.subheadline.weight(.semibold))) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose what to display in the compact resting notch when audio or video is playing:")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $store.preferences.normalStateMediaDisplay) {
                        ForEach(NormalStateMediaDisplay.allCases) { item in
                            Text(item.label).tag(item)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    
                    Text(normalStateDescription(for: store.preferences.normalStateMediaDisplay))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(14)
            }
            
            // 3. Hover Mode Dimensions
            GroupBox(label: Text("Hover Mode Dimensions (Preview Bar)").font(.subheadline.weight(.semibold))) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Controls the size of the compact preview when hovering over the notch.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Reset (500x56)") {
                            store.preferences.hoverWidth = 500.0
                            store.preferences.hoverHeight = 56.0
                        }
                        .font(.caption2)
                        .buttonStyle(.borderless)
                        .foregroundColor(.accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Hover Width")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(store.preferences.hoverWidth)) pt")
                                .monospacedDigit()
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $store.preferences.hoverWidth, in: 380...680, step: 5)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Hover Height")
                                .fontWeight(.medium)
                            Spacer()
                            if store.preferences.lockHeightOnHover {
                                Text("\(Int(store.preferences.height)) pt (Locked)")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(Int(store.preferences.hoverHeight)) pt")
                                    .monospacedDigit()
                                    .foregroundColor(.secondary)
                            }
                        }
                        Slider(value: $store.preferences.hoverHeight, in: 40...80, step: 2)
                            .disabled(store.preferences.lockHeightOnHover)
                    }
                }
                .padding(14)
            }
            
            // 4. Clicked Mode Dimensions
            GroupBox(label: Text("Clicked Mode Dimensions (Dashboard)").font(.subheadline.weight(.semibold))) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Controls the size of the enlarged dual-pod dashboard (Media Player + Lyrics / Calendar) when clicked.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Reset (580x152)") {
                            store.preferences.clickedWidth = 580.0
                            store.preferences.clickedHeight = 152.0
                        }
                        .font(.caption2)
                        .buttonStyle(.borderless)
                        .foregroundColor(.accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Clicked Width")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(store.preferences.clickedWidth)) pt")
                                .monospacedDigit()
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $store.preferences.clickedWidth, in: 480...760, step: 5)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Clicked Height")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(store.preferences.clickedHeight)) pt")
                                .monospacedDigit()
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $store.preferences.clickedHeight, in: 130...220, step: 2)
                    }
                }
                .padding(14)
            }
        }
    }
    
    private func normalStateDescription(for mode: NormalStateMediaDisplay) -> String {
        switch mode {
        case .songTitle:
            return "Shows album artwork, track title, and active playback indicator in the resting notch."
        case .lyrics:
            return "Displays live synchronized karaoke lyrics in real-time right inside the resting notch."
        case .empty:
            return "Keeps the resting notch completely black and stealthy with zero text or icons."
        }
    }
}

// MARK: - Pages & Widgets Studio Category View

private struct PagesCategoryView: View {
    @ObservedObject var store: NotchSettingsStore
    @State private var selectedPageTab: Int = 1
    
    // Targeted drop states for simulator slots
    @State private var isTargetedSlot1: Bool = false
    @State private var isTargetedSlot2: Bool = false
    @State private var isTargetedSlot3: Bool = false
    @State private var isTargetedSlot4: Bool = false
    
    private var currentPageIndex: Int {
        let idx = selectedPageTab - 1
        return max(0, min(idx, store.preferences.customPages.count - 1))
    }
    
    private var currentPage: CustomNotchPage {
        if store.preferences.customPages.indices.contains(currentPageIndex) {
            return store.preferences.customPages[currentPageIndex]
        }
        return NotchPreferences.defaultCustomPages[0]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Pages & Widgets Studio")
                    .font(.title2.weight(.semibold))
                Text("Customize up to 4 Notch pages using modular grid units (1x, 2x, 4x) with drag-and-drop slots and live preview.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 1. Apple-Style Strictly 4 Page Tabs
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    ForEach(1...4, id: \.self) { pageNum in
                        let idx = pageNum - 1
                        let page = store.preferences.customPages.indices.contains(idx)
                            ? store.preferences.customPages[idx]
                            : NotchPreferences.defaultCustomPages[idx]
                        let isSelected = selectedPageTab == pageNum
                        
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                selectedPageTab = pageNum
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "\(pageNum).circle.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(isSelected ? .white : .accentColor)
                                
                                Text(page.name.isEmpty ? "Page \(pageNum)" : page.name)
                                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.80)
                                
                                if !page.isEnabled {
                                    Text("Off")
                                        .font(.system(size: 8.5, weight: .bold))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(isSelected ? Color.white.opacity(0.25) : Color.secondary.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                            )
                            .foregroundColor(isSelected ? .white : .primary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(isSelected ? Color.clear : Color.gray.opacity(0.18), lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Page Configuration Row: Name & Enable Switch
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Page Name")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.secondary)
                        
                        TextField("Page Name", text: Binding(
                            get: { currentPage.name },
                            set: { newName in
                                if store.preferences.customPages.indices.contains(currentPageIndex) {
                                    store.preferences.customPages[currentPageIndex].name = newName
                                }
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: 240)
                    }
                    
                    Spacer()
                    
                    if selectedPageTab > 1 {
                        VStack(alignment: .trailing, spacing: 3) {
                            Text("Active Status")
                                .font(.caption2.weight(.medium))
                                .foregroundColor(.secondary)
                            
                            Toggle(isOn: Binding(
                                get: { currentPage.isEnabled },
                                set: { newValue in
                                    if store.preferences.customPages.indices.contains(currentPageIndex) {
                                        store.preferences.customPages[currentPageIndex].isEnabled = newValue
                                        NotchPageManager.shared.validateActivePage()
                                    }
                                }
                            )) {
                                Text(currentPage.isEnabled ? "Enabled" : "Disabled")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .toggleStyle(.switch)
                        }
                    } else {
                        VStack(alignment: .trailing, spacing: 3) {
                            Text("Active Status")
                                .font(.caption2.weight(.medium))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 10))
                                Text("Primary (Always Active)")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.gray.opacity(0.18), lineWidth: 0.8)
            )
            
            // 2. Modular Layout Selector (Modular Unit Box Multiples)
            GroupBox(label: Text("Modular Grid Layout (Total = 4 Units)").font(.subheadline.weight(.semibold))) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select how the active page partitions its 4-unit width:")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 10) {
                        layoutOptionCard(
                            layout: .dualPod,
                            title: "Dual-Pod",
                            units: "2x + 2x",
                            description: "Two balanced pods (50% : 50%)",
                            icon: "rectangle.split.2x1"
                        )
                        
                        layoutOptionCard(
                            layout: .fullStage,
                            title: "Full Stage",
                            units: "4x",
                            description: "Single immersive stage (100%)",
                            icon: "rectangle.fill"
                        )
                        
                        layoutOptionCard(
                            layout: .trio,
                            title: "Trio",
                            units: "1x + 1x + 2x",
                            description: "Two glances + one half pod",
                            icon: "rectangle.split.3x1"
                        )
                        
                        layoutOptionCard(
                            layout: .quad,
                            title: "Quad",
                            units: "4 × 1x",
                            description: "Four compact glances (25% each)",
                            icon: "square.grid.2x2"
                        )
                    }
                }
                .padding(12)
            }
            
            // 3. Live Interactive Notch Board Simulator (Preview & Drop Target)
            GroupBox(label: HStack(spacing: 6) {
                Text("Live Notch Simulator (Drop Target)").font(.subheadline.weight(.semibold))
                Spacer()
                Text("Drag widgets here or click slots")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }) {
                VStack(spacing: 12) {
                    // Realistic Notch Container Shape
                    ZStack(alignment: .top) {
                        // Notch Hardware Background styling
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(notchSimulatorFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.white.opacity(store.preferences.themeMode == .classicBlack ? 0.15 : 0.30), lineWidth: 1)
                            )
                        
                        VStack(spacing: 8) {
                            // Top Hardware Notch Cutout bar
                            Capsule()
                                .fill(Color.black)
                                .frame(width: 130, height: 14)
                                .overlay(
                                    Circle()
                                        .fill(Color(white: 0.18))
                                        .frame(width: 6, height: 6)
                                        .padding(.trailing, 20),
                                    alignment: .trailing
                                )
                                .padding(.top, 4)
                            
                            // Interactive Slot Grid based on currentPage.layout
                            notchSlotsSimulator
                                .padding(.horizontal, 10)
                                .padding(.bottom, 10)
                        }
                    }
                    .frame(minHeight: 136)
                }
                .padding(10)
            }
            
            // 4. Draggable Available Widgets Drawer
            GroupBox(label: HStack(spacing: 6) {
                Image(systemName: "hand.draw.fill")
                    .foregroundColor(.accentColor)
                Text("Available Widgets Library").font(.subheadline.weight(.semibold))
                Spacer()
                Text("Drag any card to a slot above")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170, maximum: 230), spacing: 10)], spacing: 10) {
                    ForEach(NotchWidgetType.allCases) { widget in
                        widgetPaletteCard(for: widget)
                    }
                }
                .padding(10)
            }
            
            // 5. Reset & Tips
            HStack(spacing: 12) {
                GroupBox {
                    HStack(spacing: 10) {
                        Image(systemName: "hand.draw")
                            .font(.system(size: 16))
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Trackpad Navigation")
                                .font(.caption.weight(.semibold))
                            Text("Swipe left or right with 2 fingers over the notch to cycle pages.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                }
                
                GroupBox {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reset All 4 Pages")
                                .font(.caption.weight(.semibold))
                            Text("Restores default Page 1-4 widget configurations.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Reset") {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                store.preferences.customPages = NotchPreferences.defaultCustomPages
                                NotchPageManager.shared.validateActivePage()
                            }
                        }
                        .font(.caption.weight(.medium))
                    }
                    .padding(8)
                }
            }
        }
    }
    
    @ViewBuilder
    private func layoutOptionCard(
        layout: PageLayoutType,
        title: String,
        units: String,
        description: String,
        icon: String
    ) -> some View {
        let isSelected = currentPage.layout == layout
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                updateLayout(layout)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                    Spacer()
                    Text(units)
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.accentColor.opacity(0.18) : Color.gray.opacity(0.15))
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                        .clipShape(Capsule())
                }
                
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.gray.opacity(0.18), lineWidth: isSelected ? 1.6 : 0.8)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var notchSimulatorFill: AnyShapeStyle {
        switch store.preferences.themeMode {
        case .classicBlack:
            return AnyShapeStyle(Color.black.opacity(0.95))
        case .liquidGlass:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.16, blue: 0.25).opacity(0.90),
                        Color(red: 0.05, green: 0.08, blue: 0.14).opacity(0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .clearGlass:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.12),
                        Color.white.opacity(0.04)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    @ViewBuilder
    private var notchSlotsSimulator: some View {
        switch currentPage.layout {
        case .dualPod:
            HStack(spacing: 8) {
                simulatorSlotCard(
                    slotNumber: 1,
                    unitLabel: "2x Pod",
                    widget: currentPage.slot1,
                    isTargeted: isTargetedSlot1
                )
                
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1, height: 60)
                
                simulatorSlotCard(
                    slotNumber: 2,
                    unitLabel: "2x Pod",
                    widget: currentPage.slot2 ?? .lyrics,
                    isTargeted: isTargetedSlot2
                )
            }
            
        case .fullStage:
            simulatorSlotCard(
                slotNumber: 1,
                unitLabel: "4x Full Stage",
                widget: currentPage.slot1,
                isTargeted: isTargetedSlot1
            )
            
        case .trio:
            HStack(spacing: 8) {
                simulatorSlotCard(
                    slotNumber: 1,
                    unitLabel: "1x Glance",
                    widget: currentPage.slot1,
                    isTargeted: isTargetedSlot1
                )
                
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1, height: 60)
                
                simulatorSlotCard(
                    slotNumber: 2,
                    unitLabel: "1x Glance",
                    widget: currentPage.slot2 ?? .hardwareHUD,
                    isTargeted: isTargetedSlot2
                )
                
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1, height: 60)
                
                simulatorSlotCard(
                    slotNumber: 3,
                    unitLabel: "2x Pod",
                    widget: currentPage.slot3 ?? .quickTools,
                    isTargeted: isTargetedSlot3
                )
            }
            
        case .quad:
            HStack(spacing: 6) {
                simulatorSlotCard(
                    slotNumber: 1,
                    unitLabel: "1x",
                    widget: currentPage.slot1,
                    isTargeted: isTargetedSlot1
                )
                
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1, height: 60)
                
                simulatorSlotCard(
                    slotNumber: 2,
                    unitLabel: "1x",
                    widget: currentPage.slot2 ?? .hardwareHUD,
                    isTargeted: isTargetedSlot2
                )
                
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1, height: 60)
                
                simulatorSlotCard(
                    slotNumber: 3,
                    unitLabel: "1x",
                    widget: currentPage.slot3 ?? .quickTools,
                    isTargeted: isTargetedSlot3
                )
                
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1, height: 60)
                
                simulatorSlotCard(
                    slotNumber: 4,
                    unitLabel: "1x",
                    widget: currentPage.slot4 ?? .scratchpad,
                    isTargeted: isTargetedSlot4
                )
            }
        }
    }
    
    @ViewBuilder
    private func simulatorSlotCard(
        slotNumber: Int,
        unitLabel: String,
        widget: NotchWidgetType,
        isTargeted: Bool
    ) -> some View {
        let isTargetedBinding: Binding<Bool> = {
            switch slotNumber {
            case 1: return $isTargetedSlot1
            case 2: return $isTargetedSlot2
            case 3: return $isTargetedSlot3
            case 4: return $isTargetedSlot4
            default: return .constant(false)
            }
        }()
        
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(isTargeted ? Color.cyan.opacity(0.20) : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(
                            isTargeted ? Color.cyan : Color.white.opacity(0.15),
                            lineWidth: isTargeted ? 2.0 : 0.8
                        )
                )
                .shadow(color: isTargeted ? Color.cyan.opacity(0.35) : Color.clear, radius: 4)
            
            VStack(spacing: 5) {
                // Top: Unit badge + Dropdown Menu
                HStack {
                    Text(unitLabel)
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Color.white.opacity(0.14))
                        .foregroundColor(.white.opacity(0.85))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Menu {
                        ForEach(NotchWidgetType.allCases) { w in
                            Button {
                                assignWidget(w, toSlot: slotNumber)
                            } label: {
                                HStack {
                                    Image(systemName: w.icon)
                                    Text(w.title)
                                    if w == widget {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 18, height: 18)
                            .background(Color.white.opacity(0.10))
                            .clipShape(Circle())
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }
                .padding(.horizontal, 8)
                .padding(.top, 6)
                
                // Widget Content (Icon & Title)
                VStack(spacing: 3) {
                    Image(systemName: widget.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(widget.title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(isTargeted ? "Drop to replace!" : "Drag widget or click")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(isTargeted ? .cyan : .white.opacity(0.45))
                        .lineLimit(1)
                }
                .padding(.bottom, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 76)
        .onDrop(of: [UTType.plainText, UTType.text], isTargeted: isTargetedBinding) { providers in
            handleDrop(providers: providers, slotNumber: slotNumber)
        }
    }
    
    @ViewBuilder
    private func widgetPaletteCard(for widget: NotchWidgetType) -> some View {
        HStack(spacing: 8) {
            // Icon Square
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: widget.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            
            // Text Details
            VStack(alignment: .leading, spacing: 2) {
                Text(widget.title)
                    .font(.system(size: 11.5, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .foregroundColor(.primary)
                
                Text(widget.subtitle)
                    .font(.system(size: 9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 3) {
                    Text("1x")
                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 3.5)
                        .padding(.vertical, 1)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    Text("2x")
                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 3.5)
                        .padding(.vertical, 1)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    Text("4x")
                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 3.5)
                        .padding(.vertical, 1)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                .foregroundColor(.secondary)
                .padding(.top, 1)
            }
            
            Spacer(minLength: 0)
            
            // Drag Grip / Quick Assign Menu
            Menu {
                Text("Assign to Current Page:").font(.caption)
                Divider()
                Button("Assign to Slot 1") {
                    assignWidget(widget, toSlot: 1)
                }
                if currentPage.layout == .dualPod || currentPage.layout == .trio || currentPage.layout == .quad {
                    Button("Assign to Slot 2") {
                        assignWidget(widget, toSlot: 2)
                    }
                }
                if currentPage.layout == .trio || currentPage.layout == .quad {
                    Button("Assign to Slot 3") {
                        assignWidget(widget, toSlot: 3)
                    }
                }
                if currentPage.layout == .quad {
                    Button("Assign to Slot 4") {
                        assignWidget(widget, toSlot: 4)
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.7))
                    .frame(width: 22, height: 26)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.gray.opacity(0.18), lineWidth: 0.8)
        )
        .contentShape(Rectangle())
        .onDrag {
            NSItemProvider(object: widget.rawValue as NSString)
        }
    }
    
    private func updateLayout(_ layout: PageLayoutType) {
        guard store.preferences.customPages.indices.contains(currentPageIndex) else { return }
        store.preferences.customPages[currentPageIndex].layout = layout
        if store.preferences.customPages[currentPageIndex].slot2 == nil {
            store.preferences.customPages[currentPageIndex].slot2 = .lyrics
        }
        if store.preferences.customPages[currentPageIndex].slot3 == nil {
            store.preferences.customPages[currentPageIndex].slot3 = .hardwareHUD
        }
        if store.preferences.customPages[currentPageIndex].slot4 == nil {
            store.preferences.customPages[currentPageIndex].slot4 = .quickTools
        }
    }
    
    private func assignWidget(_ widget: NotchWidgetType, toSlot slot: Int) {
        guard store.preferences.customPages.indices.contains(currentPageIndex) else { return }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            switch slot {
            case 1:
                store.preferences.customPages[currentPageIndex].slot1 = widget
            case 2:
                store.preferences.customPages[currentPageIndex].slot2 = widget
            case 3:
                store.preferences.customPages[currentPageIndex].slot3 = widget
            case 4:
                store.preferences.customPages[currentPageIndex].slot4 = widget
            default:
                break
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider], slotNumber: Int) -> Bool {
        guard let provider = providers.first else { return false }
        if provider.canLoadObject(ofClass: NSString.self) {
            _ = provider.loadObject(ofClass: NSString.self) { item, _ in
                if let raw = item as? String, let widget = NotchWidgetType(rawValue: raw) {
                    DispatchQueue.main.async {
                        assignWidget(widget, toSlot: slotNumber)
                    }
                }
            }
            return true
        }
        return false
    }
}

// MARK: - Display Category View

private struct DisplayCategoryView: View {
    @ObservedObject var store: NotchSettingsStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Displays & Monitors")
                    .font(.title2.weight(.semibold))
                Text("Select display target and full-screen window behavior.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Target Display")
                                .fontWeight(.medium)
                            Text("Choose which screen hosts the notch overlay.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $store.preferences.displayTarget) {
                            ForEach(DisplayTarget.allCases) { target in
                                Text(target.label).tag(target)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 220)
                    }
                    
                    Divider()
                    
                    Toggle("Keep Visible in Native Full Screen", isOn: $store.preferences.showInFullScreen)
                        .fontWeight(.medium)
                    
                    Text("Retains the notch at the top even when other apps enter native full-screen mode.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(14)
            }
        }
    }
}

// MARK: - About Category View

private struct AboutCategoryView: View {
    @ObservedObject var store: NotchSettingsStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("About YAN")
                    .font(.title2.weight(.semibold))
                Text("Application info and system utilities.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            GroupBox {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(LinearGradient(colors: [Color.cyan.opacity(0.35), Color.blue.opacity(0.20)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 52, height: 52)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(Color.cyan.opacity(0.40), lineWidth: 1)
                                )
                            
                            Image(systemName: "drop.fill")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.cyan)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("YAN — Yet Another Notch")
                                .font(.headline)
                            Text("Version 0.2.0 (Build 2)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Virtual Dynamic Notch suite with Liquid Glass for macOS.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Quick Shortcuts & Gestures:")
                            .font(.subheadline.weight(.semibold))
                        Text("• Double-click the notch to open this Settings window.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("• Right-click the notch for quick context actions.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("• Two-finger trackpad swipe left/right to switch pages.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("• Press Command + Shift + Comma (⌘ ⇧ ,) anytime.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)
            }
            
            GroupBox {
                HStack {
                    Button(role: .destructive) {
                        store.resetToDefaults()
                    } label: {
                        Text("Reset to Defaults")
                    }
                    
                    Spacer()
                    
                    Button("Close Window") {
                        SettingsWindowController.shared.close()
                    }
                    .keyboardShortcut(.cancelAction)
                    
                    Button("Quit YAN") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding(14)
            }
        }
    }
}
