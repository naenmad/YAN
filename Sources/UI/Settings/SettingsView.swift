import SwiftUI
import AppKit

public enum SettingsCategory: String, CaseIterable, Identifiable {
    case geometry = "Geometry"
    case interaction = "Interaction"
    case pages = "Pages"
    case display = "Displays"
    case about = "About"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .geometry: return "macwindow"
        case .interaction: return "cursorarrow.rays"
        case .pages: return "square.grid.2x2"
        case .display: return "display.2"
        case .about: return "info.circle"
        }
    }
}

public struct SettingsView: View {
    @ObservedObject var store: NotchSettingsStore = .shared
    @State private var selectedCategory: SettingsCategory = .geometry
    
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
                    case .geometry:
                        GeometryCategoryView(store: store)
                    case .interaction:
                        InteractionCategoryView(store: store)
                    case .pages:
                        PagesCategoryView(store: store)
                    case .display:
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
        .frame(minWidth: 700, idealWidth: 740, minHeight: 480, idealHeight: 520)
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
                    .font(.system(size: 14, weight: .medium))
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

// MARK: - Geometry Category View

private struct GeometryCategoryView: View {
    @ObservedObject var store: NotchSettingsStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Notch Geometry")
                    .font(.title2.weight(.semibold))
                Text("Configure notch dimensions and appearance for your MacBook.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 1. Notch Height
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Notch Height")
                                .fontWeight(.medium)
                            Text("The 'Menu Bar (30)' option aligns flush with the standard MacBook menu bar.")
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
            
            // 2. Notch Width
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Notch Width")
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
            
            // 3. Corner Style
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Corner Curvature")
                            .fontWeight(.medium)
                        Text("Corner and ear radii are automatically proportioned to the notch height.")
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
            
            // 4. Subtle Border Hint
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Show Subtle Border Hint", isOn: $store.preferences.showOutline)
                        .fontWeight(.medium)
                    
                    Text("Adds a razor-thin 0.5pt specular reflection so the notch silhouette is gently perceptible against pitch-black backgrounds.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    if store.preferences.showOutline {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Hint Opacity")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(store.preferences.outlineOpacity * 100))%")
                                    .font(.footnote.monospacedDigit())
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $store.preferences.outlineOpacity, in: 0.04...0.25, step: 0.02)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(14)
            }
        }
    }
}

// MARK: - Interaction Category View

private struct InteractionCategoryView: View {
    @ObservedObject var store: NotchSettingsStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Interaction & Animation")
                    .font(.title2.weight(.semibold))
                Text("Configure how the notch reacts to mouse movement and clicks.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle("Expand on Mouse Hover", isOn: $store.preferences.expandOnHover)
                        .fontWeight(.medium)
                    
                    Text("Smoothly expands when the pointer moves over the notch.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Toggle("Lock Height (Expand Horizontally Only)", isOn: $store.preferences.lockHeightOnHover)
                        .fontWeight(.medium)
                    
                    Text("Keeps height strictly locked to menu bar height (30 pt) so it never drops down or covers content on full-screen pages.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Toggle("Expand on Click", isOn: $store.preferences.expandOnClick)
                        .fontWeight(.medium)
                    
                    Text("Keeps the notch in expanded mode until clicked again.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(14)
            }
            
            // Normal State (Resting) Media Display
            GroupBox(label: Text("Normal State (Resting) Display").font(.subheadline.weight(.semibold))) {
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
            GroupBox(label: Text("Hover Mode Dimensions").font(.subheadline.weight(.semibold))) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Controls the size of the compact preview when the mouse pointer hovers over the notch.")
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
                        Text("Controls the size of the enlarged dual-pod dashboard (Media Player + Calendar) when clicked.")
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
            VStack(alignment: .leading, spacing: 4) {
                Text("Notch Pages & Order")
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
                        Text("Restores the default suite layout with all 6 pages enabled.")
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
                        Text("Navigation Tip")
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
                            Text("Choose which screen hosts the notch.")
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
                    
                    Toggle("Keep Visible in Full Screen", isOn: $store.preferences.showInFullScreen)
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
                        Image(systemName: "macwindow.badge.plus")
                            .font(.system(size: 38))
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("YAN — Yet Another Notch")
                                .font(.headline)
                            Text("Version 0.1.0 (Build 1)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Virtual Dynamic Notch utility for macOS.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Shortcuts:")
                            .font(.subheadline.weight(.medium))
                        Text("• Double-click the notch to open this window.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("• Right-click the notch for quick actions.")
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
