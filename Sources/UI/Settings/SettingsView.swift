import SwiftUI
import AppKit

public enum SettingsCategory: String, CaseIterable, Identifiable {
    case appearance = "Appearance"
    case behavior = "Behavior"
    case pages = "Pages"
    case displays = "Displays"
    case about = "About"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .appearance: return "paintpalette.fill"
        case .behavior: return "hand.tap.fill"
        case .pages: return "square.grid.2x2.fill"
        case .displays: return "display.2"
        case .about: return "info.circle.fill"
        }
    }
}

public struct SettingsView: View {
    @ObservedObject var store: NotchSettingsStore = .shared
    @State private var selectedCategory: SettingsCategory = .appearance
    
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
        .frame(minWidth: 720, idealWidth: 760, minHeight: 520, idealHeight: 560)
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

// MARK: - Pages Category View

private struct PagesCategoryView: View {
    @ObservedObject var store: NotchSettingsStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Notch Pages & Suite")
                    .font(.title2.weight(.semibold))
                Text("Enable or disable notch pages, and customize the order you swipe through them.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            GroupBox {
                VStack(spacing: 0) {
                    ForEach(Array(store.preferences.pagesOrder.enumerated()), id: \.element.id) { index, item in
                        pageRow(index: index, config: item)
                        
                        if index < store.preferences.pagesOrder.count - 1 {
                            Divider()
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding(14)
            }
            
            GroupBox {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset Page Order")
                            .font(.subheadline.weight(.medium))
                        Text("Restores the default suite layout with all 7 pages enabled.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Reset Pages") {
                        store.preferences.pagesOrder = NotchPreferences.defaultPagesOrder
                    }
                }
                .padding(12)
            }
            
            GroupBox {
                HStack(spacing: 12) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 20))
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Trackpad Navigation Tip")
                            .font(.subheadline.weight(.medium))
                        Text("Hover over the notch and swipe left or right with 2 fingers on your trackpad to cycle seamlessly across enabled pages.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
            }
        }
    }
    
    @ViewBuilder
    private func pageRow(index: Int, config: NotchPageConfig) -> some View {
        HStack(spacing: 12) {
            // Position number badge
            Text("\(index + 1)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 18)
            
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(config.isEnabled ? Color.accentColor.opacity(0.18) : Color.white.opacity(0.06))
                    .frame(width: 34, height: 34)
                
                Image(systemName: config.page.icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(config.isEnabled ? .accentColor : .secondary)
            }
            
            // Text info
            VStack(alignment: .leading, spacing: 2) {
                Text(config.page.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(config.isEnabled ? .primary : .secondary)
                Text(config.page.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Reorder Up & Down buttons
            HStack(spacing: 3) {
                Button {
                    moveUp(at: index)
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .disabled(index == 0)
                .help("Move Up")
                
                Button {
                    moveDown(at: index)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .disabled(index == store.preferences.pagesOrder.count - 1)
                .help("Move Down")
            }
            .padding(.trailing, 8)
            
            // Enable / Disable Toggle
            Toggle("", isOn: Binding(
                get: { config.isEnabled },
                set: { newValue in
                    let enabledCount = store.preferences.pagesOrder.filter { $0.isEnabled }.count
                    if !newValue && enabledCount <= 1 {
                        return
                    }
                    if let idx = store.preferences.pagesOrder.firstIndex(where: { $0.id == config.id }) {
                        store.preferences.pagesOrder[idx].isEnabled = newValue
                        NotchPageManager.shared.validateActivePage()
                    }
                }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
        }
    }
    
    private func moveUp(at index: Int) {
        guard index > 0 else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            store.preferences.pagesOrder.swapAt(index, index - 1)
        }
    }
    
    private func moveDown(at index: Int) {
        guard index < store.preferences.pagesOrder.count - 1 else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            store.preferences.pagesOrder.swapAt(index, index + 1)
        }
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
