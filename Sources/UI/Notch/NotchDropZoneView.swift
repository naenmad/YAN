import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - NotchDropZoneView (Mode Clicked / Expanded Dashboard)

public struct NotchDropZoneView: View {
    @ObservedObject private var shelf = ShelfManager.shared
    @State private var isAirDropHovered: Bool = false
    @State private var isShelfHovered: Bool = false
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 12) {
            // SISI KIRI: AirDrop Target Box (Pure Icon, No Text)
            airDropSection
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // DIVIDER TENGAH
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1)
                .padding(.vertical, 4)
            
            // SISI KANAN: Temporary Shelf / Stash Area (Pure Icon, No Text)
            shelfSection
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
    
    // MARK: - AirDrop Drop Target
    
    private var airDropSection: some View {
        Button {
            shelf.openAirDropFolder()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isAirDropHovered ? Color.cyan.opacity(0.16) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isAirDropHovered ? Color.cyan : Color.white.opacity(0.10),
                                style: StrokeStyle(lineWidth: isAirDropHovered ? 1.5 : 1, dash: isAirDropHovered ? [] : [5, 4])
                            )
                    )
                
                // Pure Icon Centered (Simpel & Minimalis)
                ZStack {
                    Circle()
                        .fill(isAirDropHovered ? Color.cyan.opacity(0.25) : Color.white.opacity(0.06))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "airdrop")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isAirDropHovered ? .cyan : .white.opacity(0.85))
                        .scaleEffect(isAirDropHovered ? 1.10 : 1.0)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onDrop(of: [.fileURL], isTargeted: $isAirDropHovered) { providers in
            shelf.extractURLs(from: providers) { urls in
                shelf.shareViaAirDrop(urls: urls)
            }
            return true
        }
        .help("AirDrop: Drop files here to share, or click to open in Finder")
    }
    
    // MARK: - Temporary Shelf Section
    
    private var shelfSection: some View {
        Group {
            if shelf.items.isEmpty {
                // Empty State: Pure Icon Centered (Simpel & Minimalis)
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isShelfHovered ? Color.cyan.opacity(0.16) : Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    isShelfHovered ? Color.cyan : Color.white.opacity(0.10),
                                    style: StrokeStyle(lineWidth: isShelfHovered ? 1.5 : 1, dash: isShelfHovered ? [] : [5, 4])
                                )
                        )
                    
                    ZStack {
                        Circle()
                            .fill(isShelfHovered ? Color.cyan.opacity(0.25) : Color.white.opacity(0.06))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "tray.and.arrow.down")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(isShelfHovered ? .cyan : .white.opacity(0.85))
                            .scaleEffect(isShelfHovered ? 1.10 : 1.0)
                    }
                }
                .contentShape(Rectangle())
                .onDrop(of: [.fileURL], isTargeted: $isShelfHovered) { providers in
                    shelf.extractURLs(from: providers) { urls in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            shelf.addItems(urls: urls)
                        }
                    }
                    return true
                }
                .help("Temporary Shelf: Drop files here to stash temporarily")
            } else {
                // List Parked Files (Bisa di-Drag Out ke aplikasi lain!)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                shelf.clearAll()
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.40))
                                .frame(width: 18, height: 18)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .help("Clear All")
                    }
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 4) {
                            ForEach(shelf.items) { item in
                                ShelfItemRow(item: item) {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        shelf.removeItem(id: item.id)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 1)
                    }
                }
                .onDrop(of: [.fileURL], isTargeted: $isShelfHovered) { providers in
                    shelf.extractURLs(from: providers) { urls in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            shelf.addItems(urls: urls)
                        }
                    }
                    return true
                }
            }
        }
    }
}

// MARK: - Shelf Item Row (Interactive Drag-Out & Remove)

private struct ShelfItemRow: View {
    let item: ShelfItem
    let onRemove: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(spacing: 7) {
            Image(nsImage: item.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(item.sizeString)
                    .font(.system(size: 7.5, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.40))
            }
            
            Spacer(minLength: 0)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(isHovered ? 0.80 : 0.30))
            }
            .buttonStyle(.plain)
            .help("Remove from shelf")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4.5)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.06))
        )
        .onHover { hovering in
            isHovered = hovering
        }
        // GESTURE DRAG OUT: Seret item ini keluar ke aplikasi lain (Finder, Telegram, Slack, VSCode, dll)
        .onDrag {
            NSItemProvider(object: item.url as NSURL)
        }
        .help("Drag this file out to drop it into any application")
    }
}

// MARK: - Compact Hover Drop Zone View (Mode Hover 56pt)

public struct NotchCompactDropZoneView: View {
    @ObservedObject private var shelf = ShelfManager.shared
    @State private var isAirDropHovered: Bool = false
    @State private var isShelfHovered: Bool = false
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 12) {
            // SISI KIRI: Compact AirDrop (Pure Icon)
            Button {
                shelf.openAirDropFolder()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isAirDropHovered ? Color.cyan.opacity(0.20) : Color.white.opacity(0.05))
                    
                    Image(systemName: "airdrop")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isAirDropHovered ? .cyan : .white.opacity(0.85))
                        .scaleEffect(isAirDropHovered ? 1.12 : 1.0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onDrop(of: [.fileURL], isTargeted: $isAirDropHovered) { providers in
                shelf.extractURLs(from: providers) { urls in
                    shelf.shareViaAirDrop(urls: urls)
                }
                return true
            }
            .help("AirDrop: Drop files here to share, or click to open in Finder")
            
            // DIVIDER
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1, height: 26)
            
            // SISI KANAN: Compact Shelf (Pure Icon)
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isShelfHovered ? Color.cyan.opacity(0.20) : Color.white.opacity(0.05))
                
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "tray.and.arrow.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isShelfHovered ? .cyan : .white.opacity(0.85))
                        .scaleEffect(isShelfHovered ? 1.12 : 1.0)
                    
                    if !shelf.items.isEmpty {
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 5, height: 5)
                            .offset(x: 4, y: -2)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onDrop(of: [.fileURL], isTargeted: $isShelfHovered) { providers in
                shelf.extractURLs(from: providers) { urls in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        shelf.addItems(urls: urls)
                    }
                }
                return true
            }
            .help("Temporary Shelf: Drop files here to stash temporarily")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }
}
