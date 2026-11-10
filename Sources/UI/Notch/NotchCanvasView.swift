import SwiftUI
import AppKit

public struct NotchCanvasView: View {
    @ObservedObject var store: NotchSettingsStore = .shared
    @State private var isHovered: Bool = false
    @State private var isExpanded: Bool = false
    
    // Callback untuk memberitahu panel agar resize window bounds jika perlu
    public var onSizeChange: ((CGSize) -> Void)?
    
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
    
    public init(onSizeChange: ((CGSize) -> Void)? = nil) {
        self.onSizeChange = onSizeChange
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            // Background Notch Shape
            NotchShape(
                cornerRadius: activeCornerRadius,
                earRadius: CGFloat(store.preferences.earRadius)
            )
            .fill(Color.black)
            .overlay(
                NotchShape(
                    cornerRadius: activeCornerRadius,
                    earRadius: CGFloat(store.preferences.earRadius)
                )
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(isHovered || isExpanded ? 0.35 : 0.0), radius: 8, x: 0, y: 4)
            
            // Konten dalam Notch saat Hover / Expanded
            if (store.preferences.expandOnHover && isHovered) || isExpanded {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    
                    Text("YAN")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                    
                    Spacer()
                    
                    Text("Settings: 2x Click")
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
            withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                isHovered = hovering
            }
        }
        .onTapGesture(count: 2) {
            SettingsWindowController.shared.show()
        }
        .onTapGesture(count: 1) {
            if store.preferences.expandOnClick {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
            }
        }
        .contextMenu {
            Button("Settings...") {
                SettingsWindowController.shared.show()
            }
            Divider()
            Button("Reset to Defaults") {
                store.resetToDefaults()
            }
            Divider()
            Button("Quit YAN") {
                NSApplication.shared.terminate(nil)
            }
        }
        .onChange(of: currentWidth) { newWidth in
            onSizeChange?(CGSize(width: newWidth, height: currentHeight))
        }
        .onChange(of: currentHeight) { newHeight in
            onSizeChange?(CGSize(width: currentWidth, height: newHeight))
        }
    }
}
