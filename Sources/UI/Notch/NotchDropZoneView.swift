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
        GeometryReader { geo in
            let availableHeight = geo.size.height
            // AirDrop dibuat kotak persegi proporsional
            let airdropSize = max(60.0, availableHeight)
            
            HStack(spacing: 12) {
                // SISI KIRI: AirDrop Target Box (KOTAK PERSEGI SAJA)
                airDropSection(size: airdropSize)
                    .frame(width: airdropSize, height: airdropSize)
                
                // DIVIDER TENGAH
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 1)
                    .padding(.vertical, 4)
                
                // SISI KANAN: Temporary Shelf (MENGISI SELURUH SISA RUANG)
                shelfSection
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
    
    // MARK: - AirDrop Drop Target (Persegi Minimalis)
    
    private func airDropSection(size: CGFloat) -> some View {
        Button {
            shelf.openAirDropFolder()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isAirDropHovered ? Color.cyan.opacity(0.20) : Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                isAirDropHovered ? Color.cyan : Color.white.opacity(0.35),
                                style: StrokeStyle(lineWidth: isAirDropHovered ? 2.0 : 1.5, dash: [6, 4])
                            )
                    )
                
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(isAirDropHovered ? Color.cyan.opacity(0.25) : Color.white.opacity(0.08))
                            .frame(width: 48, height: 48)
                        
                        Image(nsImage: ShelfManager.airDropIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                            .shadow(color: Color.black.opacity(0.35), radius: 3, x: 0, y: 1.5)
                    }
                    
                    Text("AirDrop")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(isAirDropHovered ? .cyan : .white.opacity(0.85))
                }
                .scaleEffect(isAirDropHovered ? 1.06 : 1.0)
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
    
    // MARK: - Temporary Shelf Section (Sisa Ruang)
    
    private var shelfSection: some View {
        Group {
            if shelf.items.isEmpty {
                // Empty Drop Box: Ikon Simpan Minimalis + Tulisan "Temporary"
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isShelfHovered ? Color.cyan.opacity(0.20) : Color.white.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    isShelfHovered ? Color.cyan : Color.white.opacity(0.35),
                                    style: StrokeStyle(lineWidth: isShelfHovered ? 2.0 : 1.5, dash: [6, 4])
                                )
                        )
                    
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(isShelfHovered ? Color.cyan.opacity(0.25) : Color.white.opacity(0.08))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "tray.and.arrow.down")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(isShelfHovered ? .cyan : .white.opacity(0.90))
                        }
                        
                        Text("Temporary")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(isShelfHovered ? .cyan : .white.opacity(0.85))
                    }
                    .scaleEffect(isShelfHovered ? 1.06 : 1.0)
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
                // Daftar File Terparkir (Bisa di-drag out ke aplikasi lain)
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "tray.and.arrow.down.fill")
                                .font(.system(size: 8.5))
                                .foregroundColor(.cyan)
                            Text("\(shelf.items.count)")
                                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                                .foregroundColor(.cyan)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cyan.opacity(0.12))
                        .clipShape(Capsule())
                        
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
                        .help("Clear All Files")
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
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.03))
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
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.06))
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .onDrag {
            NSItemProvider(object: item.url as NSURL)
        }
        .help("Drag this file out to drop it into any application")
    }
}

// MARK: - Compact Hover Drop Zone View (Mode Hover 56pt)

public struct NotchCompactDropZoneView: View {
    @ObservedObject private var shelf = ShelfManager.shared
    @ObservedObject private var store = NotchSettingsStore.shared
    @State private var isAirDropHovered: Bool = false
    @State private var isShelfHovered: Bool = false
    
    public init() {}
    
    public var body: some View {
        let hoverH = CGFloat(store.preferences.hoverHeight)
        let boxHeight = max(32.0, hoverH - 14.0)
        let airdropSize = boxHeight
        
        HStack(spacing: 10) {
            // SISI KIRI: Compact AirDrop (Kotak Persegi dengan Outline Putus-putus Jelas)
            Button {
                shelf.openAirDropFolder()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(isAirDropHovered ? Color.cyan.opacity(0.20) : Color.white.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(
                                    isAirDropHovered ? Color.cyan : Color.white.opacity(0.35),
                                    style: StrokeStyle(lineWidth: isAirDropHovered ? 1.6 : 1.2, dash: [4.5, 3.5])
                                )
                        )
                    
                    VStack(spacing: 2) {
                        Image(nsImage: ShelfManager.airDropIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 17, height: 17)
                        
                        Text("AirDrop")
                            .font(.system(size: 7.5, weight: .semibold, design: .rounded))
                            .foregroundColor(isAirDropHovered ? .cyan : .white.opacity(0.85))
                    }
                    .scaleEffect(isAirDropHovered ? 1.06 : 1.0)
                }
                .frame(width: airdropSize, height: airdropSize)
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
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: max(18.0, boxHeight - 12))
            
            // SISI KANAN: Compact Shelf (Mengisi Seluruh Sisa Ruang dengan Outline Putus-putus Jelas)
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isShelfHovered ? Color.cyan.opacity(0.20) : Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(
                                isShelfHovered ? Color.cyan : Color.white.opacity(0.35),
                                style: StrokeStyle(lineWidth: isShelfHovered ? 1.6 : 1.2, dash: [4.5, 3.5])
                            )
                    )
                
                VStack(spacing: 2) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "tray.and.arrow.down")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(isShelfHovered ? .cyan : .white.opacity(0.90))
                        
                        if !shelf.items.isEmpty {
                            Circle()
                                .fill(Color.cyan)
                                .frame(width: 4.5, height: 4.5)
                                .offset(x: 4, y: -2)
                        }
                    }
                    
                    Text("Temporary")
                        .font(.system(size: 7.5, weight: .semibold, design: .rounded))
                        .foregroundColor(isShelfHovered ? .cyan : .white.opacity(0.85))
                }
                .scaleEffect(isShelfHovered ? 1.06 : 1.0)
            }
            .frame(height: boxHeight)
            .frame(maxWidth: .infinity)
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
        .frame(maxWidth: .infinity, maxHeight: hoverH, alignment: .center)
        .padding(.horizontal, 10)
    }
}
