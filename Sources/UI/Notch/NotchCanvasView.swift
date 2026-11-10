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
        if store.preferences.lockHeightOnHover {
            return base
        }
        if (store.preferences.expandOnHover && isHovered) || isExpanded {
            return base * CGFloat(store.preferences.hoverScaleHeight)
        }
        return base
    }
    
    private var activeCornerRadius: CGFloat {
        let base = CGFloat(store.preferences.cornerRadius)
        if (store.preferences.expandOnHover && isHovered) || isExpanded {
            return base + 2.0
        }
        return base
    }
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                // 1. Solid Black Notch Body
                NotchShape(
                    cornerRadius: activeCornerRadius,
                    earRadius: CGFloat(store.preferences.earRadius)
                )
                .fill(Color.black)
                .shadow(color: Color.black.opacity(isHovered || isExpanded ? 0.35 : 0.0), radius: 10, x: 0, y: 5)
                
                // 2. Faint Rim Hint (Razor-thin 0.5pt specular reflection)
                if store.preferences.showOutline {
                    NotchBorderShape(
                        cornerRadius: activeCornerRadius,
                        earRadius: CGFloat(store.preferences.earRadius)
                    )
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(store.preferences.outlineOpacity),
                                Color.white.opacity(store.preferences.outlineOpacity * 0.45),
                                Color.white.opacity(store.preferences.outlineOpacity)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
                }
                
                // 3. Content shown when expanded
                if (store.preferences.expandOnHover && isHovered) || isExpanded {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 5, height: 5)
                        
                        Text("YAN")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                        
                        Spacer()
                        
                        Text("Settings: Double-click")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.50))
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
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
                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                    isHovered = hovering
                }
            }
            .onTapGesture(count: 2) {
                SettingsWindowController.shared.show()
            }
            .onTapGesture(count: 1) {
                if store.preferences.expandOnClick {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
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
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)) { _ in
            isHovered = false
        }
    }
}
