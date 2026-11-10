import SwiftUI
import AppKit

public struct NotchQuickToolsView: View {
    @ObservedObject private var tools = QuickToolsManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 8) {
            // Grid 4 Tombol Utilitas Mikro
            HStack(spacing: 10) {
                // 1. Keep Awake (Caffeine)
                QuickToolCard(
                    title: "Keep Awake",
                    subtitle: tools.isCaffeineActive ? "Active (No Sleep)" : "Click to Enable",
                    icon: "cup.and.saucer.fill",
                    tintColor: tools.isCaffeineActive ? .orange : .white,
                    isActive: tools.isCaffeineActive,
                    action: {
                        tools.toggleCaffeine()
                    }
                )
                
                // 2. Color Eyedropper
                QuickToolCard(
                    title: "Color Picker",
                    subtitle: tools.lastSampledHex ?? "Pick Screen Hex",
                    icon: "eyedropper.halffull",
                    tintColor: tools.lastSampledHex != nil ? Color(hex: tools.lastSampledHex!) ?? .cyan : .cyan,
                    isActive: false,
                    action: {
                        tools.pickScreenColor()
                    }
                )
                
                // 3. Screen Capture Area
                QuickToolCard(
                    title: "Capture Area",
                    subtitle: "Copy to Clipboard",
                    icon: "viewfinder",
                    tintColor: .white,
                    isActive: false,
                    action: {
                        tools.triggerScreenCapture()
                    }
                )
                
                // 4. Mic Mute / Sound
                QuickToolCard(
                    title: tools.isMicMuted ? "Mic Muted" : "Mic Active",
                    subtitle: "Click to Toggle",
                    icon: tools.isMicMuted ? "mic.slash.fill" : "mic.fill",
                    tintColor: tools.isMicMuted ? .red : .green,
                    isActive: tools.isMicMuted,
                    action: {
                        tools.toggleMicMute()
                    }
                )
            }
            .frame(maxHeight: .infinity)
            
            // Subtle Feedback Toast
            if let toast = tools.toastMessage {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 8))
                    Text(toast)
                        .font(.system(size: 8.5, weight: .semibold, design: .rounded))
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
        .padding(.vertical, 10)
    }
}

// MARK: - Quick Tool Card Component

private struct QuickToolCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let tintColor: Color
    let isActive: Bool
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isActive ? tintColor.opacity(0.18) : (isHovered ? Color.white.opacity(0.10) : Color.white.opacity(0.04)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isActive ? tintColor.opacity(0.60) : (isHovered ? Color.white.opacity(0.20) : Color.white.opacity(0.06)),
                                lineWidth: 1
                            )
                    )
                
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(isActive ? tintColor.opacity(0.25) : Color.white.opacity(0.08))
                            .frame(width: 34, height: 34)
                        
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(tintColor)
                    }
                    
                    VStack(spacing: 1.5) {
                        Text(title)
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(subtitle)
                            .font(.system(size: 7.5, weight: .medium))
                            .foregroundColor(.white.opacity(0.45))
                            .lineLimit(1)
                    }
                }
                .padding(6)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Compact Hover Quick Tools View (Mode Hover 56pt)

public struct NotchCompactQuickToolsView: View {
    @ObservedObject private var tools = QuickToolsManager.shared
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 14) {
            // Keep Awake Button
            Button {
                tools.toggleCaffeine()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 10))
                        .foregroundColor(tools.isCaffeineActive ? .orange : .white.opacity(0.85))
                    Text(tools.isCaffeineActive ? "Awake" : "Sleep OK")
                        .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                        .foregroundColor(tools.isCaffeineActive ? .orange : .white.opacity(0.60))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(tools.isCaffeineActive ? Color.orange.opacity(0.18) : Color.white.opacity(0.06))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            // Eyedropper Button
            Button {
                tools.pickScreenColor()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "eyedropper.halffull")
                        .font(.system(size: 10))
                        .foregroundColor(.cyan)
                    Text("Picker")
                        .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.70))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            // Screenshot Button
            Button {
                tools.triggerScreenCapture()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.85))
                    Text("Capture")
                        .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.70))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            // Mic Mute Button
            Button {
                tools.toggleMicMute()
            } label: {
                Image(systemName: tools.isMicMuted ? "mic.slash.fill" : "mic.fill")
                    .font(.system(size: 11))
                    .foregroundColor(tools.isMicMuted ? .red : .green)
                    .frame(width: 22, height: 22)
                    .background(tools.isMicMuted ? Color.red.opacity(0.18) : Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
