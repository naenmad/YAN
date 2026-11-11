import SwiftUI
import AppKit

// MARK: - NotchQuickToolsView (Mode Clicked / 152pt)

public struct NotchQuickToolsView: View {
    @ObservedObject private var tools = QuickToolsManager.shared
    @ObservedObject private var store = NotchSettingsStore.shared
    
    public init() {}
    
    public var body: some View {
        let currentW = CGFloat(store.preferences.clickedWidth)
        let currentH = CGFloat(store.preferences.clickedHeight)
        let availableW = max(360.0, currentW - 53)
        let leftWidth = max(230.0, availableW * 0.54)
        let rightWidth = max(190.0, availableW - leftWidth)
        let dividerHeight = max(70.0, currentH - 32)
        
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                // SISI KIRI: System Controls & Privacy
                VStack(alignment: .leading, spacing: 8) {
                    // Header Sisi Kiri
                    HStack(spacing: 5) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.cyan)
                        Text("SYSTEM CONTROLS")
                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                            .tracking(0.8)
                            .foregroundColor(.white.opacity(0.85))
                        
                        Spacer()
                    }
                    
                    // 1. Keep Awake Control Tile
                    HStack(spacing: 9) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(tools.isCaffeineActive ? Color.cyan.opacity(0.20) : Color.white.opacity(0.06))
                                .frame(width: 30, height: 30)
                            
                            Image(systemName: "display")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(tools.isCaffeineActive ? .cyan : .white.opacity(0.85))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Keep Awake")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Text(tools.isCaffeineActive ? "Sleep Prevented (Active)" : "Standard Sleep Mode")
                                .font(.system(size: 8.5, weight: .regular))
                                .foregroundColor(.white.opacity(0.40))
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { tools.isCaffeineActive },
                            set: { _ in tools.toggleCaffeine() }
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .scaleEffect(0.72)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.035))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    
                    // 2. Microphone Hardware Mute Tile
                    HStack(spacing: 9) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(tools.isMicMuted ? Color.red.opacity(0.20) : Color.white.opacity(0.06))
                                .frame(width: 30, height: 30)
                            
                            Image(systemName: tools.isMicMuted ? "mic.slash.fill" : "mic.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(tools.isMicMuted ? .red : .white.opacity(0.85))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Microphone")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Text(tools.isMicMuted ? "Hardware Input Muted" : "Microphone Active")
                                .font(.system(size: 8.5, weight: .regular))
                                .foregroundColor(.white.opacity(0.40))
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { !tools.isMicMuted },
                            set: { _ in tools.toggleMicMute() }
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .scaleEffect(0.72)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.035))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .frame(width: leftWidth)
                
                // DIVIDER TENGAH (Identik dengan Dashboard)
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 1, height: dividerHeight)
                
                // SISI KANAN: Precision Utilities & Capture
                VStack(alignment: .leading, spacing: 8) {
                    // Header Sisi Kanan
                    HStack(spacing: 5) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.cyan)
                        Text("QUICK UTILITIES")
                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                            .tracking(0.8)
                            .foregroundColor(.white.opacity(0.85))
                        
                        Spacer()
                    }
                    
                    // 1. Color Eyedropper Card
                    HStack(spacing: 9) {
                        if let hex = tools.lastSampledHex, let color = Color(hex: hex) {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(color)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                                )
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                                    .frame(width: 30, height: 30)
                                Image(systemName: "eyedropper")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Color Picker")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Text(tools.lastSampledHex ?? "Sample Screen Hex")
                                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                                .foregroundColor(tools.lastSampledHex != nil ? .cyan : .white.opacity(0.40))
                        }
                        
                        Spacer()
                        
                        Button {
                            tools.pickScreenColor()
                        } label: {
                            Text(tools.lastSampledHex != nil ? "Resample" : "Sample")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4.5)
                                .background(Color.white.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.035))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    
                    // 2. Precision Screen Capture Card
                    HStack(spacing: 9) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 30, height: 30)
                            Image(systemName: "viewfinder")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Screen Snip")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Interactive Area -> Clipboard")
                                .font(.system(size: 8.5, weight: .regular))
                                .foregroundColor(.white.opacity(0.40))
                        }
                        
                        Spacer()
                        
                        Button {
                            tools.triggerScreenCapture()
                        } label: {
                            Text("Capture")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4.5)
                                .background(Color.white.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.035))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .frame(width: rightWidth)
            }
            
            // Subtle Feedback Toast at bottom
            if let toast = tools.toastMessage {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 7.5, weight: .bold))
                    Text(toast)
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.cyan)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.cyan.opacity(0.12))
                .clipShape(Capsule())
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
    }
}

// MARK: - Compact Hover Quick Tools View (Mode Hover 56pt)

public struct NotchCompactQuickToolsView: View {
    @ObservedObject private var tools = QuickToolsManager.shared
    @ObservedObject private var store = NotchSettingsStore.shared
    
    public init() {}
    
    public var body: some View {
        let hoverH = CGFloat(store.preferences.hoverHeight)
        let dividerH = max(20.0, hoverH - 26.0)
        
        HStack(spacing: 12) {
            // SISI KIRI: System Controls (Keep Awake & Mic)
            HStack(spacing: 8) {
                // Keep Awake Toggle Button
                Button {
                    tools.toggleCaffeine()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "display")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(tools.isCaffeineActive ? .cyan : .white.opacity(0.85))
                        Text(tools.isCaffeineActive ? "Awake: ON" : "Awake: OFF")
                            .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                            .foregroundColor(tools.isCaffeineActive ? .cyan : .white.opacity(0.70))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(tools.isCaffeineActive ? Color.cyan.opacity(0.18) : Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                // Mic Mute Toggle Button
                Button {
                    tools.toggleMicMute()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tools.isMicMuted ? "mic.slash.fill" : "mic.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(tools.isMicMuted ? .red : .white.opacity(0.85))
                        Text(tools.isMicMuted ? "Muted" : "Mic Active")
                            .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                            .foregroundColor(tools.isMicMuted ? .red : .white.opacity(0.70))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(tools.isMicMuted ? Color.red.opacity(0.18) : Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // DIVIDER TENGAH
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: dividerH)
            
            // SISI KANAN: Utilities (Eyedropper & Screen Snip)
            HStack(spacing: 8) {
                // Eyedropper Button
                Button {
                    tools.pickScreenColor()
                } label: {
                    HStack(spacing: 5) {
                        if let hex = tools.lastSampledHex, let col = Color(hex: hex) {
                            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                .fill(col)
                                .frame(width: 12, height: 12)
                        } else {
                            Image(systemName: "eyedropper")
                                .font(.system(size: 9.5, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        Text(tools.lastSampledHex ?? "Picker")
                            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(tools.lastSampledHex != nil ? .cyan : .white.opacity(0.75))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                // Screen Snip Button
                Button {
                    tools.triggerScreenCapture()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                        Text("Snip")
                            .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .frame(width: 165)
        }
        .frame(maxWidth: .infinity, maxHeight: hoverH, alignment: .center)
        .padding(.horizontal, 10)
    }
}
