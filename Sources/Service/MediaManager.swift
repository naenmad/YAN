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
        
        // 3. Fallback ringan setiap 2 detik jika stream idle
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
            
            // Ambil lirik baru jika lagu berganti dan ini adalah musik
            if !isVideo && (previousTrack?.title != title || previousTrack?.artist != artist) {
                self.activeLyrics = []
                self.currentLyric = nil
                
                if !artist.isEmpty && !title.isEmpty {
                    Task {
                        let lyrics = await LyricsService.shared.fetchLyrics(artist: artist, title: title)
                        await MainActor.run {
                            self.activeLyrics = lyrics
                            self.updateActiveLyric()
                        }
                    }
                }
            }
        } else {
            // Stream melaporkan idle atau kosong
            if currentTrack != nil && !(currentTrack?.isPlaying ?? false) {
                // Biarkan track terakhir tetap tampil beberapa saat dalam mode pause
            }
        }
    }
    
    private func checkActiveMediaFallback() {
        // Jika stream belum menangkap track tapi ada Apple Music yang aktif berjalan
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
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func updateActiveLyric() {
        guard let track = currentTrack, !activeLyrics.isEmpty else {
            if currentLyric != nil {
                currentLyric = nil
            }
            return
        }
        
        let currentPos = track.elapsedTime
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
    }
    
    public func nextTrack() {
        MediaRemoteBridge.shared.nextTrack()
    }
    
    public func previousTrack() {
        MediaRemoteBridge.shared.previousTrack()
    }
}
