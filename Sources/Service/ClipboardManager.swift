import Foundation
import AppKit
import SwiftUI

public enum ClipboardItemType: String, Codable {
    case text
    case link
    case color
    case image
}

public struct ClipboardItem: Identifiable, Equatable {
    public let id: UUID
    public let content: String // For text/url/hex, or descriptive "Screenshot • 1440×900"
    public let type: ClipboardItemType
    public let date: Date
    public let color: Color?
    public let image: NSImage?
    public let imageData: Data?
    
    // Initializer untuk Text, Link, dan Color
    public init(content: String) {
        self.id = UUID()
        self.content = content
        self.date = Date()
        self.image = nil
        self.imageData = nil
        
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#") && (trimmed.count == 7 || trimmed.count == 4 || trimmed.count == 9) {
            self.type = .color
            self.color = Color(hex: trimmed)
        } else if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            self.type = .link
            self.color = nil
        } else {
            self.type = .text
            self.color = nil
        }
    }
    
    // Initializer untuk Gambar / Screenshot
    public init(image: NSImage, imageData: Data, description: String) {
        self.id = UUID()
        self.content = description
        self.type = .image
        self.date = Date()
        self.color = nil
        self.image = image
        self.imageData = imageData
    }
    
    public static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.id == rhs.id && lhs.content == rhs.content && lhs.type == rhs.type
    }
}

public struct PinnedSnippet: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var content: String
    
    public init(title: String, content: String) {
        self.id = UUID()
        self.title = title
        self.content = content
    }
}

@MainActor
public final class ClipboardManager: ObservableObject {
    public static let shared = ClipboardManager()
    
    @Published public var history: [ClipboardItem] = []
    @Published public var pinnedSnippets: [PinnedSnippet] = []
    
    private var lastChangeCount: Int = -1
    private var timer: Timer?
    private let maxHistoryCount = 20
    private let pinnedStorageKey = "com.yan.notchanothernotch.pinnedSnippets"
    
    private init() {
        loadPinnedSnippets()
        startMonitoring()
    }
    
    public func startMonitoring() {
        lastChangeCount = NSPasteboard.general.changeCount
        checkPasteboard()
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkPasteboard()
            }
        }
    }
    
    public func checkPasteboard() {
        let currentCount = NSPasteboard.general.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount
        
        // 1. Cek apakah ada data gambar / screenshot (PNG atau TIFF)
        if let imgData = NSPasteboard.general.data(forType: .png) ?? NSPasteboard.general.data(forType: .tiff),
           let nsImage = NSImage(data: imgData) {
            
            // Hindari duplikasi jika ukuran byte persis sama dengan item gambar paling atas
            if let first = history.first, first.type == .image, first.imageData?.count == imgData.count {
                return
            }
            
            let w = Int(nsImage.size.width)
            let h = Int(nsImage.size.height)
            let desc = "Screenshot • \(w)×\(h)"
            let newItem = ClipboardItem(image: nsImage, imageData: imgData, description: desc)
            
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                history.insert(newItem, at: 0)
                if history.count > maxHistoryCount {
                    history.removeLast()
                }
            }
            return
        }
        
        // 2. Cek apakah ada teks string
        guard let string = NSPasteboard.general.string(forType: .string),
              !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Hindari duplikasi persis dari entri teks terakhir
        if let first = history.first, first.content == string {
            return
        }
        
        let newItem = ClipboardItem(content: string)
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            history.removeAll(where: { $0.content == string && $0.type != .image })
            history.insert(newItem, at: 0)
            if history.count > maxHistoryCount {
                history.removeLast()
            }
        }
    }
    
    public func copyItem(_ item: ClipboardItem) {
        NSPasteboard.general.clearContents()
        if item.type == .image {
            if let png = item.imageData {
                NSPasteboard.general.setData(png, forType: .png)
            }
            if let tiff = item.image?.tiffRepresentation {
                NSPasteboard.general.setData(tiff, forType: .tiff)
            }
        } else {
            NSPasteboard.general.setString(item.content, forType: .string)
        }
        lastChangeCount = NSPasteboard.general.changeCount
        HapticService.shared.success()
    }
    
    public func copy(content: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        lastChangeCount = NSPasteboard.general.changeCount
        HapticService.shared.success()
    }
    
    public func clearHistory() {
        withAnimation(.easeInOut(duration: 0.2)) {
            history.removeAll()
        }
    }
    
    public func addSnippet(title: String, content: String) {
        guard !title.isEmpty, !content.isEmpty else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            pinnedSnippets.append(PinnedSnippet(title: title, content: content))
            savePinnedSnippets()
        }
    }
    
    public func removeSnippet(id: UUID) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            pinnedSnippets.removeAll(where: { $0.id == id })
            savePinnedSnippets()
        }
    }
    
    private func loadPinnedSnippets() {
        guard let data = UserDefaults.standard.data(forKey: pinnedStorageKey),
              let list = try? JSONDecoder().decode([PinnedSnippet].self, from: data) else {
            self.pinnedSnippets = [
                PinnedSnippet(title: "My Email", content: "hello@example.com"),
                PinnedSnippet(title: "Zoom Link", content: "https://zoom.us/j/my-room")
            ]
            return
        }
        self.pinnedSnippets = list
    }
    
    private func savePinnedSnippets() {
        if let data = try? JSONEncoder().encode(pinnedSnippets) {
            UserDefaults.standard.set(data, forKey: pinnedStorageKey)
        }
    }
}

// Extension to convert Hex string to SwiftUI Color
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let length = hexSanitized.count
        let r, g, b, a: Double
        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
