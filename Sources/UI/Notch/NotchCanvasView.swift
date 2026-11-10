import SwiftUI
import AppKit

public struct NotchCanvasView: View {
    @ObservedObject var store: NotchSettingsStore = .shared
    @State private var isHovered: Bool = false
    @State private var isExpanded: Bool = false
    
    private var currentWidth: CGFloat {
        let base = CGFloat(store.preferences.width)
        if (store.preferences.expandOnHover && isHovered) || isExpanded {
            return base * CGFloat(store.preferences.hoverScaleWidth)
        }
        return base
    }
    
    private var currentHeight: CGFloat {
        let base = CGFloat(store.preferences.height)
        if (store.preferences.expandOnHover && isHovered) || isExpanded {
            return base * CGFloat(store.preferences.hoverScaleHeight)
        }
        return base
    }
    
    private var activeCornerRadius: CGFloat {
        let base = CGFloat(store.preferences.cornerRadius)
        if (store.preferences.expandOnHover && isHovered) || isExpanded {
            return base + 4.0
        }
        return base
    }
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                // Siluet Notch Utama
                NotchShape(
                    cornerRadius: activeCornerRadius,
                    earRadius: CGFloat(store.preferences.earRadius)
                )
                .fill(Color.black)
                .shadow(color: Color.black.opacity(isHovered || isExpanded ? 0.45 : 0.0), radius: 12, x: 0, y: 6)
                
                // Konten Notch saat Mode Terbuka (Hover / Expanded)
                if (store.preferences.expandOnHover && isHovered) || isExpanded {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        
                        Text("YAN")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                        
                        Spacer()
                        
                        Text("Pengaturan: 2x Klik")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .frame(width: currentWidth, height: currentHeight)
            .contentShape(
                NotchShape(
                    cornerRadius: activeCornerRadius,
                    earRadius: CGFloat(store.preferences.earRadius)
                )
            )
            .onHover { hovering in
                guard store.preferences.expandOnHover else { return }
                withAnimation(.spring(response: 0.30, dampingFraction: 0.72)) {
                    isHovered = hovering
                }
            }
            .onTapGesture(count: 2) {
                SettingsWindowController.shared.show()
            }
            .onTapGesture(count: 1) {
                if store.preferences.expandOnClick {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.72)) {
                        isExpanded.toggle()
                    }
                }
            }
            .contextMenu {
                Button("Pengaturan...") {
                    SettingsWindowController.shared.show()
                }
                Divider()
                Button("Reset ke Pengaturan Awal") {
                    store.resetToDefaults()
                }
                Divider()
                Button("Keluar dari YAN") {
                    NSApplication.shared.terminate(nil)
                }
            }
            
            // Spacer mendorong notch selalu menempel rapat di tepi atas jendela
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
