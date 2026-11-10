import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject var store: NotchSettingsStore = .shared
    
    public var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Lebar (Width)")
                        Spacer()
                        Text("\(Int(store.preferences.width)) pt")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $store.preferences.width, in: 100...360, step: 2)
                    
                    HStack {
                        Text("Tinggi (Height)")
                        Spacer()
                        Text("\(Int(store.preferences.height)) pt")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $store.preferences.height, in: 20...56, step: 1)
                    
                    HStack {
                        Text("Corner Radius")
                        Spacer()
                        Text("\(Int(store.preferences.cornerRadius)) pt")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $store.preferences.cornerRadius, in: 4...28, step: 1)
                    
                    HStack {
                        Text("Top Ear Radius")
                        Spacer()
                        Text("\(Int(store.preferences.earRadius)) pt")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $store.preferences.earRadius, in: 0...16, step: 1)
                }
            } header: {
                Label("Geometri Notch", systemImage: "macbook.gen1")
                    .font(.headline)
            }
            
            Section {
                Toggle("Expand saat Hover Mouse", isOn: $store.preferences.expandOnHover)
                Toggle("Expand saat Diklik", isOn: $store.preferences.expandOnClick)
                
                if store.preferences.expandOnHover || store.preferences.expandOnClick {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Skala Lebar Expand")
                            Spacer()
                            Text(String(format: "%.2fx", store.preferences.hoverScaleWidth))
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $store.preferences.hoverScaleWidth, in: 1.1...1.8, step: 0.05)
                        
                        HStack {
                            Text("Skala Tinggi Expand")
                            Spacer()
                            Text(String(format: "%.2fx", store.preferences.hoverScaleHeight))
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $store.preferences.hoverScaleHeight, in: 1.1...2.2, step: 0.05)
                    }
                    .padding(.top, 4)
                }
            } header: {
                Label("Interaksi & Trigger", systemImage: "cursorarrow.rays")
                    .font(.headline)
            }
            
            Section {
                Toggle("Tetap Tampil saat Mode Fullscreen", isOn: $store.preferences.showInFullScreen)
                Toggle("Tampilkan di Monitor Eksternal", isOn: $store.preferences.multiMonitorEnabled)
            } header: {
                Label("Layar & Monitor", systemImage: "display.2")
                    .font(.headline)
            }
            
            Section {
                HStack {
                    Button(role: .destructive) {
                        store.resetToDefaults()
                    } label: {
                        Text("Reset ke Default")
                    }
                    
                    Spacer()
                    
                    Button("Tutup Jendela") {
                        SettingsWindowController.shared.close()
                    }
                    .keyboardShortcut(.cancelAction)
                    
                    Button("Quit YAN") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 500)
    }
}
