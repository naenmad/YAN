import SwiftUI
import AppKit

public enum SettingsCategory: String, CaseIterable, Identifiable {
    case geometry = "Geometri"
    case interaction = "Interaksi"
    case display = "Layar & Monitor"
    case about = "Tentang"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .geometry: return "macwindow"
        case .interaction: return "cursorarrow.rays"
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
                Text("Pengaturan")
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
                Text("Geometri Notch")
                    .font(.title2.weight(.semibold))
                Text("Pilih ukuran standar yang selaras dengan menu bar MacBook kamu.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 1. Tinggi Notch
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Tinggi Notch")
                                .fontWeight(.medium)
                            Text("Pilihan 'Menu Bar (30)' rata sempurna dengan menu bar MacBook Air.")
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
                        Text("Kompak (26)").tag(HeightPreset.compact)
                        Text("Menu Bar (30)").tag(HeightPreset.menuBar)
                        Text("Besar (36)").tag(HeightPreset.tall)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
                .padding(14)
            }
            
            // 2. Lebar Notch
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Lebar Notch")
                                .fontWeight(.medium)
                            Text("Pilih preset lebar atau geser slider untuk ukuran kustom.")
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
                        Text("Kompak (160)").tag(WidthPreset.compact)
                        Text("Standar (200)").tag(WidthPreset.standard)
                        Text("Lebar (260)").tag(WidthPreset.wide)
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
            
            // 3. Gaya Lekukan
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Gaya & Lekukan Sudut")
                            .fontWeight(.medium)
                        Text("Kelengkungan sudut dihitung otomatis dan proporsional terhadap tinggi notch.")
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
        }
    }
}

// MARK: - Interaction Category View

private struct InteractionCategoryView: View {
    @ObservedObject var store: NotchSettingsStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Interaksi & Animasi")
                    .font(.title2.weight(.semibold))
                Text("Atur respons notch saat kursor mendekat atau menyentuh area.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle("Expand saat Hover Mouse", isOn: $store.preferences.expandOnHover)
                        .fontWeight(.medium)
                    
                    Text("Notch mengembang halus saat kursor berada di atas area notch.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Toggle("Kunci Tinggi Notch (Hanya Melebar ke Samping)", isOn: $store.preferences.lockHeightOnHover)
                        .fontWeight(.medium)
                    
                    Text("Tinggi notch akan tetap persis setinggi menu bar (30 pt) tanpa bertambah panjang ke bawah saat kursor mendekat.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Toggle("Expand saat Diklik", isOn: $store.preferences.expandOnClick)
                        .fontWeight(.medium)
                    
                    Text("Notch membuka mode lebar saat diklik.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(14)
            }
            
            if (store.preferences.expandOnHover || store.preferences.expandOnClick) && !store.preferences.lockHeightOnHover {
                GroupBox(label: Text("Skala Animasi Ekspansi").font(.subheadline.weight(.semibold))) {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Skala Lebar Ekspansi")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(String(format: "%.2fx", store.preferences.hoverScaleWidth))
                                    .monospacedDigit()
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $store.preferences.hoverScaleWidth, in: 1.1...1.6, step: 0.05)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Skala Tinggi Ekspansi")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(String(format: "%.2fx", store.preferences.hoverScaleHeight))
                                    .monospacedDigit()
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $store.preferences.hoverScaleHeight, in: 1.0...1.35, step: 0.05)
                        }
                    }
                    .padding(14)
                }
            }
        }
    }
}

// MARK: - Display Category View

private struct DisplayCategoryView: View {
    @ObservedObject var store: NotchSettingsStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Layar & Monitor")
                    .font(.title2.weight(.semibold))
                Text("Tentukan lokasi tampilan notch pada monitor yang tersambung.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Target Monitor")
                                .fontWeight(.medium)
                            Text("Pilih layar tempat notch ditampilkan.")
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
                        .frame(width: 200)
                    }
                    
                    Divider()
                    
                    Toggle("Tetap Tampil saat Mode Fullscreen", isOn: $store.preferences.showInFullScreen)
                        .fontWeight(.medium)
                    
                    Text("Notch tetap berada di posisi atas meskipun aplikasi lain masuk ke mode full screen.")
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
                Text("Tentang YAN")
                    .font(.title2.weight(.semibold))
                Text("Informasi aplikasi dan utilitas sistem.")
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
                            Text("Versi 0.1.0 (Build 1)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Virtual Dynamic Notch utility untuk macOS.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Pintasan:")
                            .font(.subheadline.weight(.medium))
                        Text("• Double-click pada notch untuk membuka jendela ini.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("• Klik kanan pada notch untuk menu cepat.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("• Tekan Command + Shift + Comma (⌘ ⇧ ,) kapan saja.")
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
                        Text("Reset ke Pengaturan Awal")
                    }
                    
                    Spacer()
                    
                    Button("Tutup Jendela") {
                        SettingsWindowController.shared.close()
                    }
                    .keyboardShortcut(.cancelAction)
                    
                    Button("Keluar dari YAN") {
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
