import SwiftUI
import AppKit

// MARK: - NotchWidgetHostView (Modular Widget Host Router)

public struct NotchWidgetHostView: View {
    public let type: NotchWidgetType
    public let size: WidgetSize
    
    public init(type: NotchWidgetType, size: WidgetSize = .medium) {
        self.type = type
        self.size = size
    }
    
    public var body: some View {
        Group {
            switch type {
            case .nowPlaying:
                NowPlayingWidgetView(size: size)
            case .lyrics:
                LyricsWidgetView(size: size)
            case .calendar:
                CalendarWidgetView(size: size)
            case .shelf:
                ShelfWidgetView(size: size)
            case .clipboard:
                ClipboardWidgetView(size: size)
            case .hardwareHUD:
                HardwareHUDWidgetView(size: size)
            case .quickTools:
                QuickToolsWidgetView(size: size)
            case .scratchpad:
                ScratchpadWidgetView(size: size)
            case .camera:
                CameraWidgetView(size: size)
            }
        }
    }
}

// MARK: - 1. Music & Media Player Widget

public struct NowPlayingWidgetView: View {
    public let size: WidgetSize
    @ObservedObject private var media = MediaManager.shared
    
    private var hasActiveMedia: Bool {
        media.currentTrack != nil && media.currentTrack!.isValid
    }
    
    public var body: some View {
        switch size {
        case .small:
            smallGlance
        case .medium:
            mediumPod
        case .large:
            largeStage
        }
    }
    
    // Small: Compact Glance (Untuk Hover bar atau baris ringkas)
    private var smallGlance: some View {
        HStack(spacing: 8) {
            if hasActiveMedia, let track = media.currentTrack {
                if let art = track.artwork {
                    Image(nsImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                } else {
                    Image(systemName: track.mediaType == .video ? "play.rectangle.fill" : "music.note")
                        .font(.system(size: 11))
                        .foregroundColor(.cyan)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    MarqueeText(track.title, fontSize: 10, fontWeight: .bold, color: .white)
                    Text(track.artist.isEmpty ? track.sourceApp : track.artist)
                        .font(.system(size: 8.5))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(1)
                }
                .frame(maxWidth: 130, alignment: .leading)
                
                Button {
                    media.togglePlayPause()
                } label: {
                    Image(systemName: track.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 20, height: 20)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 5) {
                    Image(systemName: "music.note")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.40))
                    Text("No Media")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.50))
                }
            }
        }
    }
    
    // Medium: Dedicated Pod (Standard Dual-Pod Half Stage)
    private var mediumPod: some View {
        Group {
            if hasActiveMedia, let track = media.currentTrack {
                VStack(alignment: .leading, spacing: 7) {
                    // Artwork + Title + Artist
                    HStack(spacing: 10) {
                        ZStack(alignment: .bottomTrailing) {
                            if let art = track.artwork {
                                Image(nsImage: art)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: track.mediaType == .video ? "play.rectangle.fill" : "music.note")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white.opacity(0.70))
                                    )
                            }
                            
                            if track.mediaType == .video {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 6.5))
                                    .foregroundColor(.white)
                                    .padding(2)
                                    .background(Color.black.opacity(0.85))
                                    .clipShape(Circle())
                                    .offset(x: 2, y: 2)
                            }
                        }
                        .shadow(color: Color.black.opacity(0.35), radius: 3, x: 0, y: 1.5)
                        
                        VStack(alignment: .leading, spacing: 2.5) {
                            MarqueeText(track.title, fontSize: 12, fontWeight: .bold, color: .white)
                            
                            Text(track.artist.isEmpty ? track.sourceApp : track.artist)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.65))
                                .lineLimit(1)
                            
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(track.isPlaying ? Color.green : Color.orange)
                                    .frame(width: 4.5, height: 4.5)
                                Text(track.sourceApp)
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.40))
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    
                    // Scrubber Timeline
                    MediaScrubberView(
                        duration: track.duration,
                        currentTime: media.currentPlaybackPosition,
                        onSeek: { targetTime in media.seek(to: targetTime) }
                    )
                    
                    // Controls
                    HStack(spacing: 18) {
                        Spacer()
                        Button { media.previousTrack() } label: {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 26, height: 26)
                        }
                        .buttonStyle(.plain)
                        
                        Button { media.togglePlayPause() } label: {
                            Image(systemName: track.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 12.5, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)
                        
                        Button { media.nextTrack() } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 26, height: 26)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 44, height: 44)
                            Image(systemName: "music.note")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white.opacity(0.40))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No Media Playing")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.90))
                            Text("Ready for playback")
                                .font(.system(size: 9.5, weight: .regular))
                                .foregroundColor(.white.opacity(0.40))
                        }
                        Spacer(minLength: 0)
                    }
                    Spacer(minLength: 0)
                    HStack {
                        Spacer()
                        Button { media.togglePlayPause() } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill").font(.system(size: 10, weight: .bold))
                                Text("Resume").font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.white)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
    
    // Large: Full Single Stage (100% Width)
    private var largeStage: some View {
        HStack(spacing: 18) {
            mediumPod
                .frame(maxWidth: 280)
            
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.cyan)
                    Text("PLAYBACK DETAILS")
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .foregroundColor(.cyan)
                        .tracking(0.6)
                }
                
                if let track = media.currentTrack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(track.album.isEmpty ? "Single / Stream Track" : track.album)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                        
                        Text("Source: \(track.sourceApp)")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.45))
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - 2. Live Synchronized Lyrics Widget

public struct LyricsWidgetView: View {
    public let size: WidgetSize
    @ObservedObject private var media = MediaManager.shared
    
    public var body: some View {
        switch size {
        case .small:
            smallGlance
        case .medium:
            mediumStage
        case .large:
            largeTeleprompter
        }
    }
    
    private var smallGlance: some View {
        HStack(spacing: 6) {
            Image(systemName: "music.note")
                .font(.system(size: 9))
                .foregroundColor(.cyan)
            MarqueeText(
                media.currentLyric ?? (media.currentTrack?.title ?? "No lyrics"),
                fontSize: 10,
                fontWeight: .semibold,
                color: .cyan
            )
        }
    }
    
    private var mediumStage: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundColor(.cyan)
                Text("LYRICS")
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                    .tracking(0.6)
                Spacer()
            }
            
            if !media.activeLyrics.isEmpty {
                let currentLine = media.currentLyric
                let prevLine = media.previousLyric
                let nextLine = media.nextLyric
                let upcomingLine: String? = {
                    guard let curr = currentLine,
                          let idx = media.activeLyrics.firstIndex(where: { $0.text == curr }),
                          idx + 2 < media.activeLyrics.count else { return nil }
                    return media.activeLyrics[idx + 2].text
                }()
                
                VStack(alignment: .leading, spacing: 4.5) {
                    Spacer(minLength: 0)
                    Text(prevLine ?? " ")
                        .font(.system(size: 9.5, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.28))
                        .lineLimit(1)
                    
                    HStack(spacing: 5) {
                        Image(systemName: "music.note")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.cyan)
                        MarqueeText(currentLine ?? "Instrumental", fontSize: 12, fontWeight: .bold, color: .cyan)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color.cyan.opacity(0.12))
                            .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(Color.cyan.opacity(0.28), lineWidth: 0.8))
                    )
                    
                    Text(nextLine ?? " ")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.48))
                        .lineLimit(1)
                    
                    if let upcoming = upcomingLine {
                        Text(upcoming)
                            .font(.system(size: 9, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.25))
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
            } else {
                VStack(spacing: 6) {
                    Spacer()
                    Image(systemName: "music.quarternote.3").font(.system(size: 18)).foregroundColor(.white.opacity(0.25))
                    Text("No Synced Lyrics").font(.system(size: 10.5, weight: .semibold, design: .rounded)).foregroundColor(.white.opacity(0.60))
                    Text("Play a track to view live lyrics").font(.system(size: 8.5)).foregroundColor(.white.opacity(0.35))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private var largeTeleprompter: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.cyan)
                Text("KARAOKE TELEPROMPTER")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                    .tracking(0.6)
                Spacer()
            }
            
            if !media.activeLyrics.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Spacer(minLength: 0)
                    Text(media.previousLyric ?? " ")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.35))
                    
                    HStack(spacing: 7) {
                        Image(systemName: "music.note")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.cyan)
                        MarqueeText(media.currentLyric ?? "Instrumental", fontSize: 14, fontWeight: .bold, color: .cyan)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.cyan.opacity(0.14))
                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Color.cyan.opacity(0.32), lineWidth: 1))
                    )
                    
                    Text(media.nextLyric ?? " ")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                    Spacer(minLength: 0)
                }
            } else {
                VStack(spacing: 6) {
                    Spacer()
                    Image(systemName: "music.quarternote.3").font(.system(size: 24)).foregroundColor(.white.opacity(0.25))
                    Text("No Synced Lyrics Available").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundColor(.white.opacity(0.70))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - 3. Calendar & Agenda Widget

public struct CalendarWidgetView: View {
    public let size: WidgetSize
    
    public var body: some View {
        switch size {
        case .small:
            NotchCalendarView(isLarge: false)
        case .medium, .large:
            NotchCalendarView(isLarge: true)
        }
    }
}

// MARK: - 4. Drop Zone & Shelf Widget

public struct ShelfWidgetView: View {
    public let size: WidgetSize
    @ObservedObject private var shelf = ShelfManager.shared
    
    public var body: some View {
        switch size {
        case .small:
            NotchCompactDropZoneView()
        case .medium:
            mediumShelf
        case .large:
            NotchDropZoneView()
        }
    }
    
    private var mediumShelf: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "tray.and.arrow.down.fill")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.cyan)
                Text("DROP SHELF")
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                    .tracking(0.6)
                Spacer()
                Text("\(shelf.items.count) items")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.40))
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.30), style: StrokeStyle(lineWidth: 1.2, dash: [5, 3]))
                    .background(Color.white.opacity(0.04))
                
                if shelf.items.isEmpty {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.50))
                        Text("Drop Files Here")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.65))
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(shelf.items) { item in
                                VStack(spacing: 2) {
                                    Image(nsImage: item.icon)
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                    Text(item.name)
                                        .font(.system(size: 8))
                                        .foregroundColor(.white.opacity(0.80))
                                        .lineLimit(1)
                                        .frame(width: 48)
                                }
                            }
                        }
                        .padding(6)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - 5. Clipboard Manager Widget

public struct ClipboardWidgetView: View {
    public let size: WidgetSize
    
    public var body: some View {
        switch size {
        case .small:
            NotchCompactClipboardView()
        case .medium, .large:
            NotchClipboardView()
        }
    }
}

// MARK: - 6. Hardware HUD Widget

public struct HardwareHUDWidgetView: View {
    public let size: WidgetSize
    
    public var body: some View {
        switch size {
        case .small:
            NotchCompactHardwareHUDView()
        case .medium, .large:
            NotchHardwareHUDView()
        }
    }
}

// MARK: - 7. Quick Tools Widget

public struct QuickToolsWidgetView: View {
    public let size: WidgetSize
    
    public var body: some View {
        switch size {
        case .small:
            NotchCompactQuickToolsView()
        case .medium, .large:
            NotchQuickToolsView()
        }
    }
}

// MARK: - 8. Scratchpad & Notes Widget

public struct ScratchpadWidgetView: View {
    public let size: WidgetSize
    
    public var body: some View {
        switch size {
        case .small:
            NotchCompactScratchpadView()
        case .medium, .large:
            NotchScratchpadView()
        }
    }
}

// MARK: - 9. Notch Mirror / Camera Widget

public struct CameraWidgetView: View {
    public let size: WidgetSize
    
    public var body: some View {
        switch size {
        case .small:
            NotchCompactCameraView()
        case .medium, .large:
            NotchCameraView()
        }
    }
}
