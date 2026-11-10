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
            // SISI KIRI: AirDrop Target Box
            airDropSection
                .frame(maxWidth: .infinity)
            
            // DIVIDER TENGAH
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1)
                .padding(.vertical, 8)
            
            // SISI KANAN: Temporary Shelf / Stash Area
            shelfSection
                .frame(maxWidth: .infinity)
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
                    .fill(isAirDropHovered ? Color.cyan.opacity(0.16) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isAirDropHovered ? Color.cyan : Color.white.opacity(0.12),
                                style: StrokeStyle(lineWidth: isAirDropHovered ? 1.5 : 1, dash: isAirDropHovered ? [] : [5, 4])
                            )
                    )
                
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(isAirDropHovered ? Color.cyan.opacity(0.25) : Color.white.opacity(0.08))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "airdrop")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isAirDropHovered ? .cyan : .white.opacity(0.90))
                    }
                    
                    VStack(spacing: 2) {
                        Text("AirDrop")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(isAirDropHovered ? "Release to Send" : "Drop files here to share")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(isAirDropHovered ? .cyan : .white.opacity(0.45))
                    }
                    
                    Text("Click to Open in Finder")
                        .font(.system(size: 7.5, weight: .semibold))
                        .foregroundColor(.white.opacity(0.30))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                }
                .padding(8)
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
        .help("Drop files here to share via AirDrop, or click to open Finder AirDrop")
    }
    
    // MARK: - Temporary Shelf Section
    
    private var shelfSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header Shelf: Title + Badge Count + Clear All
            HStack(spacing: 6) {
                Image(systemName: "tray.and.arrow.down.fill")
                    .font(.system(size: 9.5))
                    .foregroundColor(.cyan)
                
                Text("Temporary Shelf")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                if !shelf.items.isEmpty {
                    Text("\(shelf.items.count)")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.cyan)
                        .clipShape(Capsule())
                }
                
                Spacer(minLength: 0)
                
                if !shelf.items.isEmpty {
                    Button("Clear All") {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            shelf.clearAll()
                        }
                    }
                    .font(.system(size: 8, weight: .medium))
                    .buttonStyle(.plain)
                    .foregroundColor(.red.opacity(0.85))
                }
            }
            
            if shelf.items.isEmpty {
                // Empty State Drop Box
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isShelfHovered ? Color.cyan.opacity(0.14) : Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    isShelfHovered ? Color.cyan : Color.white.opacity(0.10),
                                    style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                                )
                        )
                    
                    VStack(spacing: 3) {
                        Image(systemName: "plus.square.dashed")
                            .font(.system(size: 16))
                            .foregroundColor(isShelfHovered ? .cyan : .white.opacity(0.40))
                        
                        Text(isShelfHovered ? "Drop to Park Files" : "Drop items to stash temporarily")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(isShelfHovered ? .cyan : .white.opacity(0.70))
                        
                        Text("Drag out to any app or chat anytime")
                            .font(.system(size: 7.5, weight: .regular))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .padding(8)
                }
                .frame(maxHeight: .infinity)
                .onDrop(of: [.fileURL], isTargeted: $isShelfHovered) { providers in
                    shelf.extractURLs(from: providers) { urls in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            shelf.addItems(urls: urls)
                        }
                    }
                    return true
                }
            } else {
                // List Parked Files (Bisa di-Drag Out ke aplikasi lain!)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 5) {
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
                .frame(maxHeight: .infinity)
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
            // SISI KIRI: Compact AirDrop
            Button {
                shelf.openAirDropFolder()
            } label: {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(isAirDropHovered ? Color.cyan.opacity(0.3) : Color.white.opacity(0.10))
                            .frame(width: 26, height: 26)
                        
                        Image(systemName: "airdrop")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(isAirDropHovered ? .cyan : .white)
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("AirDrop")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(isAirDropHovered ? "Drop to Send!" : "Drop files to share")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(isAirDropHovered ? .cyan : .white.opacity(0.45))
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isAirDropHovered ? Color.cyan.opacity(0.15) : Color.white.opacity(0.05))
                )
            }
            .buttonStyle(.plain)
            .onDrop(of: [.fileURL], isTargeted: $isAirDropHovered) { providers in
                shelf.extractURLs(from: providers) { urls in
                    shelf.shareViaAirDrop(urls: urls)
                }
                return true
            }
            
            // DIVIDER
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1, height: 28)
            
            // SISI KANAN: Compact Shelf
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isShelfHovered ? Color.cyan.opacity(0.3) : Color.white.opacity(0.10))
                        .frame(width: 26, height: 26)
                    
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isShelfHovered ? .cyan : .white.opacity(0.90))
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(shelf.items.isEmpty ? "Temporary Shelf" : "Shelf (\(shelf.items.count))")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundColor(shelf.items.isEmpty ? .white : .cyan)
                    Text(isShelfHovered ? "Drop to Park!" : (shelf.items.isEmpty ? "Drop items to stash" : "Drag files out anytime"))
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(isShelfHovered ? .cyan : .white.opacity(0.45))
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isShelfHovered ? Color.cyan.opacity(0.15) : Color.white.opacity(0.05))
            )
            .onDrop(of: [.fileURL], isTargeted: $isShelfHovered) { providers in
                shelf.extractURLs(from: providers) { urls in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        shelf.addItems(urls: urls)
                    }
                }
                return true
            }
        }
        .padding(.horizontal, 10)
    }
}
