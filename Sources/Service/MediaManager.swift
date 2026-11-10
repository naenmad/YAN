import Foundation
import AppKit

@MainActor
public final class MediaManager: ObservableObject {
    public static let shared = MediaManager()
    
    @Published public var currentTrack: MediaTrack?
    @Published public var currentLyric: String?
    
    private var activeLyrics: [LyricLine] = []
    private var lyricTimer: Timer?
    private var fallbackTimer: Timer?
    
    // Tracking waktu pemutaran real-time
    private var lastPlaybackTime: TimeInterval = 0
    private var lastPlaybackTimestamp: Date = Date()
    private var isTrackPlaying: Bool = false
    
    private init() {
        startMonitoring()
    }
    
    public func startMonitoring() {
        // 1. Dapatkan update stream dari MediaRemoteAdapter
        MediaRemoteBridge.shared.onNowPlayingUpdate = { [weak self] payload in
            Task { @MainActor in
                self?.handlePayload(payload)
            }
        }
        MediaRemoteBridge.shared.startStream()
        
        // 2. Timer sinkronisasi lirik setiap 0.5 detik
        let lTimer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateActiveLyric()
            }
        }
        RunLoop.main.add(lTimer, forMode: .common)
        self.lyricTimer = lTimer
        
        // 3. Fallback ringan setiap 2 detik jika stream belum menangkap
        let fTimer = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkActiveMediaFallback()
            }
        }
        RunLoop.main.add(fTimer, forMode: .common)
        self.fallbackTimer = fTimer
    }
    
    public func handlePayload(_ payload: NowPlayingPayload) {
        if let rawTitle = payload.title, !rawTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let artist = (payload.artist ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let album = (payload.album ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let duration = payload.duration ?? 0
            let elapsedTime = payload.elapsedTime ?? 0
            let isPlaying = payload.playing ?? false
            
            self.lastPlaybackTime = elapsedTime
            self.lastPlaybackTimestamp = Date()
            self.isTrackPlaying = isPlaying
            
            var artworkImage: NSImage? = nil
            if let b64 = payload.artworkData, let data = Data(base64Encoded: b64) {
                artworkImage = NSImage(data: data)
            }
            
            let bundle = (payload.bundleIdentifier ?? "").lowercased()
            let isBrowser = bundle.contains("chrome") || bundle.contains("safari") || bundle.contains("neo") || bundle.contains("brave") || bundle.contains("arc")
            let isVideo = isBrowser || (album.isEmpty && (duration > 360 || title.lowercased().contains("youtube")))
            let mediaType: MediaType = isVideo ? .video : .music
            
            var sourceName = "Media Player"
            if bundle.contains("music") {
                sourceName = "Apple Music"
            } else if bundle.contains("spotify") {
                sourceName = "Spotify"
            } else if isBrowser {
                sourceName = "YouTube / Web"
            } else if !artist.isEmpty {
                sourceName = artist
            }
            
            let previousTrack = self.currentTrack
            let newTrack = MediaTrack(
                title: title,
                artist: artist.isEmpty ? sourceName : artist,
                album: album,
                artwork: artworkImage,
                isPlaying: isPlaying,
                duration: duration,
                elapsedTime: elapsedTime,
                mediaType: mediaType,
                sourceApp: sourceName
            )
            
            self.currentTrack = newTrack
            
            // Selalu cari lirik untuk semua media yang memiliki judul (baik Apple Music, Spotify, maupun YouTube)
            if previousTrack?.title != title || previousTrack?.artist != artist {
                self.activeLyrics = []
                self.currentLyric = nil
                
                Task {
                    let lyrics = await LyricsService.shared.fetchLyrics(artist: artist, title: title)
                    await MainActor.run {
                        self.activeLyrics = lyrics
                        if let first = lyrics.first {
                            self.currentLyric = first.text
                        }
                        self.updateActiveLyric()
                    }
                }
            }
        }
    }
    
    private func checkActiveMediaFallback() {
        guard currentTrack == nil else { return }
        
        let musicApps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music")
        if !musicApps.isEmpty {
            DispatchQueue.global(qos: .utility).async {
                let script = """
                tell application "Music"
                    try
                        if player state is playing then
                            set trackName to name of current track
                            set trackArtist to artist of current track
                            set trackAlbum to album of current track
                            set trackDur to duration of current track
                            set trackPos to player position
                            return trackName & "|||" & trackArtist & "|||" & trackAlbum & "|||" & trackDur & "|||" & trackPos
                        end if
                    end try
                end tell
                return ""
                """
                var error: NSDictionary?
                if let appleScript = NSAppleScript(source: script) {
                    let result = appleScript.executeAndReturnError(&error)
                    if let stringValue = result.stringValue, !stringValue.isEmpty {
                        let parts = stringValue.components(separatedBy: "|||")
                        if parts.count >= 5 {
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self, self.currentTrack == nil else { return }
                                let track = MediaTrack(
                                    title: parts[0],
                                    artist: parts[1].isEmpty ? "Apple Music" : parts[1],
                                    album: parts[2],
                                    artwork: nil,
                                    isPlaying: true,
                                    duration: Double(parts[3]) ?? 0,
                                    elapsedTime: Double(parts[4]) ?? 0,
                                    mediaType: .music,
                                    sourceApp: "Apple Music"
                                )
                                self.currentTrack = track
                                self.lastPlaybackTime = track.elapsedTime
                                self.lastPlaybackTimestamp = Date()
                                self.isTrackPlaying = true
                                
                                Task {
                                    let lyrics = await LyricsService.shared.fetchLyrics(artist: parts[1], title: parts[0])
                                    await MainActor.run {
                                        self.activeLyrics = lyrics
                                        self.updateActiveLyric()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func updateActiveLyric() {
        guard !activeLyrics.isEmpty else { return }
        
        let elapsedSince = isTrackPlaying ? Date().timeIntervalSince(lastPlaybackTimestamp) : 0
        let currentPos = max(0, lastPlaybackTime + elapsedSince)
        
        Task {
            if let lyric = await LyricsService.shared.currentLyric(from: activeLyrics, at: currentPos) {
                await MainActor.run {
                    self.currentLyric = lyric
                }
            }
        }
    }
    
    public func togglePlayPause() {
        MediaRemoteBridge.shared.togglePlayPause()
        currentTrack?.isPlaying.toggle()
        isTrackPlaying.toggle()
        lastPlaybackTimestamp = Date()
    }
    
    public func nextTrack() {
        MediaRemoteBridge.shared.nextTrack()
    }
    
    public func previousTrack() {
        MediaRemoteBridge.shared.previousTrack()
    }
}
