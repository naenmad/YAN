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
    @State private var selectedCategory: SettingsCategory? = .geometry
    
    public var body: some View {
        NavigationSplitView {
            List(SettingsCategory.allCases, selection: $selectedCategory) { category in
                Label(category.rawValue, systemImage: category.icon)
                    .tag(category)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
        } detail: {
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
                    case .none:
                        Text("Pilih kategori pengaturan di sidebar.")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 620, idealWidth: 660, minHeight: 400, idealHeight: 460)
    }
}

// MARK: - Subviews

private struct GeometryCategoryView: View {
    @ObservedObject var store: NotchSettingsStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Geometri Notch")
                    .font(.title2.weight(.semibold))
                Text("Sesuaikan ukuran dan lekukan notch virtual pada layar.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            GroupBox {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Lebar (Width)")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(store.preferences.width)) pt")
                                .monospacedDigit()
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $store.preferences.width, in: 120...360, step: 2)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Tinggi (Height)")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(store.preferences.height)) pt")
                                .monospacedDigit()
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $store.preferences.height, in: 20...56, step: 1)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Radius Sudut Bawah (Corner Radius)")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(store.preferences.cornerRadius)) pt")
                                .monospacedDigit()
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $store.preferences.cornerRadius, in: 4...28, step: 1)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Radius Telinga Atas (Ear Radius)")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(store.preferences.earRadius)) pt")
                                .monospacedDigit()
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $store.preferences.earRadius, in: 0...16, step: 1)
                    }
                }
                .padding(14)
            }
        }
    }
}

private struct InteractionCategoryView: View {
    @ObservedObject var store: NotchSettingsStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Interaksi & Animasi")
                    .font(.title2.weight(.semibold))
                Text("Atur respons notch saat berinteraksi dengan kursor mouse.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle("Expand saat Hover Mouse", isOn: $store.preferences.expandOnHover)
                        .fontWeight(.medium)
                    
                    Text("Notch mengembang secara dinamis dengan animasi spring ketika kursor menyentuh area notch.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Toggle("Expand saat Diklik", isOn: $store.preferences.expandOnClick)
                        .fontWeight(.medium)
                    
                    Text("Notch tetap dalam mode terbuka hingga diklik kembali.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(14)
            }
            
            if store.preferences.expandOnHover || store.preferences.expandOnClick {
                GroupBox(label: Text("Skala Animasi Ekspansi").font(.subheadline.weight(.semibold))) {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Skala Lebar")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(String(format: "%.2fx", store.preferences.hoverScaleWidth))
                                    .monospacedDigit()
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $store.preferences.hoverScaleWidth, in: 1.1...1.8, step: 0.05)
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Skala Tinggi")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(String(format: "%.2fx", store.preferences.hoverScaleHeight))
                                    .monospacedDigit()
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $store.preferences.hoverScaleHeight, in: 1.1...2.2, step: 0.05)
                        }
                    }
                    .padding(14)
                }
            }
        }
    }
}

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
                        VStack(alignment: .leading, spacing: 4) {
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
