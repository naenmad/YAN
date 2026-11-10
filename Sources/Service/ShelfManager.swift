import Foundation
import AppKit
import UniformTypeIdentifiers

public struct ShelfItem: Identifiable, Equatable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let icon: NSImage
    public let sizeString: String
    public let dateAdded: Date
    
    public init(url: URL) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
        
        let rawIcon = NSWorkspace.shared.icon(forFile: url.path)
        let copy = rawIcon.copy() as? NSImage ?? rawIcon
        copy.size = NSSize(width: 32, height: 32)
        self.icon = copy
        
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let bytes = attrs[.size] as? Int64 {
            let bcf = ByteCountFormatter()
            bcf.allowedUnits = [.useAll]
            bcf.countStyle = .file
            self.sizeString = bcf.string(fromByteCount: bytes)
        } else {
            self.sizeString = "--"
        }
        self.dateAdded = Date()
    }
    
    public static func == (lhs: ShelfItem, rhs: ShelfItem) -> Bool {
        return lhs.id == rhs.id
    }
}

@MainActor
public final class ShelfManager: ObservableObject {
    public static let shared = ShelfManager()
    
    @Published public var items: [ShelfItem] = []
    
    private init() {}
    
    public func addItems(urls: [URL]) {
        for url in urls {
            // Hindari duplikasi file dengan URL sama
            if !items.contains(where: { $0.url.standardizedFileURL == url.standardizedFileURL }) {
                items.append(ShelfItem(url: url))
            }
        }
    }
    
    public func removeItem(id: UUID) {
        items.removeAll(where: { $0.id == id })
    }
    
    public func clearAll() {
        items.removeAll()
    }
    
    public func shareViaAirDrop(urls: [URL]) {
        guard !urls.isEmpty else { return }
        DispatchQueue.main.async {
            if let service = NSSharingService(named: .sendViaAirDrop) {
                if service.canPerform(withItems: urls) {
                    service.perform(withItems: urls)
                }
            }
        }
    }
    
    public func openAirDropFolder() {
        DispatchQueue.global(qos: .userInitiated).async {
            let script = """
            tell application "Finder" to activate
            tell application "System Events"
                tell process "Finder"
                    click menu item "AirDrop" of menu "Go" of menu bar 1
                end tell
            end tell
            """
            var err: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&err)
        }
    }
    
    public func extractURLs(from providers: [NSItemProvider], completion: @escaping ([URL]) -> Void) {
        let group = DispatchGroup()
        var collectedURLs: [URL] = []
        let lock = NSLock()
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    defer { group.leave() }
                    if let url = item as? URL {
                        lock.lock()
                        collectedURLs.append(url)
                        lock.unlock()
                    } else if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        lock.lock()
                        collectedURLs.append(url)
                        lock.unlock()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(collectedURLs)
        }
    }
}
