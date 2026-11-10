import Foundation
import AppKit

public enum MediaType: String, Codable {
    case music
    case video
    case unknown
}

public struct LyricLine: Identifiable, Equatable {
    public let id = UUID()
    public let time: TimeInterval
    public let text: String
    
    public init(time: TimeInterval, text: String) {
        self.time = time
        self.text = text
    }
}

public struct MediaTrack: Equatable {
    public var title: String
    public var artist: String
    public var album: String
    public var artwork: NSImage?
    public var isPlaying: Bool
    public var duration: TimeInterval
    public var elapsedTime: TimeInterval
    public var mediaType: MediaType
    public var sourceApp: String
    
    public init(
        title: String = "",
        artist: String = "",
        album: String = "",
        artwork: NSImage? = nil,
        isPlaying: Bool = false,
        duration: TimeInterval = 0,
        elapsedTime: TimeInterval = 0,
        mediaType: MediaType = .music,
        sourceApp: String = ""
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.artwork = artwork
        self.isPlaying = isPlaying
        self.duration = duration
        self.elapsedTime = elapsedTime
        self.mediaType = mediaType
        self.sourceApp = sourceApp
    }
    
    public var isValid: Bool {
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public static func == (lhs: MediaTrack, rhs: MediaTrack) -> Bool {
        return lhs.title == rhs.title &&
               lhs.artist == rhs.artist &&
               lhs.isPlaying == rhs.isPlaying &&
               lhs.sourceApp == rhs.sourceApp
    }
}
