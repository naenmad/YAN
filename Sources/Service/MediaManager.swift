import Foundation
import AppKit
import Combine

@MainActor
public final class MediaManager: ObservableObject {
    public static let shared = MediaManager()
    
    @Published public var currentTrack: MediaTrack?
    @Published public var currentLyric: String?
    
    private var activeLyrics: [LyricLine] = []
    private var pollTimer: Timer?
    private var lyricTimer: Timer?
    
    private init() {
        startMonitoring()
    }
    
    public func startMonitoring() {
        // Notifikasi sistem saat Now Playing berubah
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        
        // Polling ringan setiap 1.5 detik sebagai backup
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        
        // Timer sinkronisasi lirik setiap 0.5 detik
        lyricTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateActiveLyric()
            }
        }
        
        refresh()
    }
    
    public func refresh() {
        MediaRemoteBridge.shared.fetchNowPlayingInfo { [weak self] info in
            Task { @MainActor in
                self?.handleNowPlayingInfo(info)
            }
        }
    }
    
    private func handleNowPlayingInfo(_ info: [String: Any]) {
        guard let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String, !title.isEmpty else {
            if currentTrack != nil {
                self.currentTrack = nil
                self.currentLyric = nil
                self.activeLyrics = []
            }
            return
        }
        
        let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
        let album = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? ""
        let duration = info["kMRMediaRemoteNowPlayingInfoDuration"] as? Double ?? 0
        let elapsedTime = info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double ?? 0
        let rate = info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0
        let isPlaying = rate > 0
        
        var artworkImage: NSImage? = nil
        if let data = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
            artworkImage = NSImage(data: data)
        }
        
        let isVideo = album.isEmpty && (duration > 300 || title.lowercased().contains("youtube") || artist.isEmpty)
        let mediaType: MediaType = isVideo ? .video : .music
        
        let previousTrack = self.currentTrack
        let newTrack = MediaTrack(
            title: title,
            artist: artist,
            album: album,
            artwork: artworkImage,
            isPlaying: isPlaying,
            duration: duration,
            elapsedTime: elapsedTime,
            mediaType: mediaType,
            sourceApp: isVideo ? "Video" : "Music"
        )
        
        self.currentTrack = newTrack
        
        // Jika berganti lagu, ambil lirik baru
        if previousTrack?.title != title || previousTrack?.artist != artist {
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
    }
    
    private func updateActiveLyric() {
        guard let track = currentTrack, track.isPlaying, !activeLyrics.isEmpty else {
            return
        }
        
        // Update perkiraan waktu pemutaran
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refresh()
        }
    }
    
    public func previousTrack() {
        MediaRemoteBridge.shared.previousTrack()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refresh()
        }
    }
}
