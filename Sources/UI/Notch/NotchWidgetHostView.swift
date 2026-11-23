import SwiftUI
import AppKit
import Combine
import UniformTypeIdentifiers

// MARK: - NotchWidgetHostView (Modular Dynamic Widget Host Router)

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
            case .clockTimer:
                ClockTimerWidgetView(size: size)
            case .networkSpeed:
                NetworkSpeedWidgetView(size: size)
            case .appLauncher:
                AppLauncherWidgetView(size: size)
            case .weather:
                WeatherWidgetView(size: size)
            case .miniCalculator:
                CalculatorWidgetView(size: size)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        case .hover:
            hoverGlance
        case .small:
            smallClickedCard
        case .medium:
            mediumPod
        case .large:
            largeStage
        }
    }
    
    // Hover: Single-row horizontal music player with full controls (< 30pt height)
    private var hoverGlance: some View {
        HStack(spacing: 8) {
            if hasActiveMedia, let track = media.currentTrack {
                if let art = track.artwork {
                    Image(nsImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.6)
                        )
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 28, height: 28)
                        Image(systemName: track.mediaType == .video ? "play.rectangle.fill" : "music.note")
                            .font(.system(size: 11))
                            .foregroundColor(.cyan)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    MarqueeText(track.title, fontSize: 10, fontWeight: .bold, color: .white)
                    Text(track.artist.isEmpty ? track.sourceApp : track.artist)
                        .font(.system(size: 8.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(1)
                    
                    if track.duration > 0 {
                        let prog = min(1.0, max(0.0, media.currentPlaybackPosition / track.duration))
                        GeometryReader { barGeo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.12))
                                Capsule().fill(Color.cyan)
                                    .frame(width: max(2, barGeo.size.width * CGFloat(prog)))
                            }
                        }
                        .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 4) {
                    Button {
                        HapticService.shared.click()
                        media.previousTrack()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 7.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.70))
                            .frame(width: 18, height: 18)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        HapticService.shared.click()
                        media.togglePlayPause()
                    } label: {
                        Image(systemName: track.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 22, height: 22)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.25), radius: 2, y: 1)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        HapticService.shared.click()
                        media.nextTrack()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 7.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.70))
                            .frame(width: 18, height: 18)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack(spacing: 5) {
                    Image(systemName: "music.note")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.40))
                    Text("No Media Playing")
                        .font(.system(size: 9.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.50))
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    // Small: Clicked 1x unit box (Trio/Quad, ~115pt x 110pt)
    private var smallClickedCard: some View {
        VStack(spacing: 4) {
            if hasActiveMedia, let track = media.currentTrack {
                if let art = track.artwork {
                    Image(nsImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Color.white.opacity(0.15), lineWidth: 0.6))
                } else {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: track.mediaType == .video ? "play.rectangle.fill" : "music.note")
                                .font(.system(size: 15))
                                .foregroundColor(.cyan)
                        )
                }
                
                MarqueeText(track.title, fontSize: 10, fontWeight: .bold, color: .white)
                    .frame(maxWidth: .infinity)
                
                Text(track.artist.isEmpty ? track.sourceApp : track.artist)
                    .font(.system(size: 8.5, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Button { media.previousTrack() } label: {
                        Image(systemName: "backward.fill").font(.system(size: 9)).foregroundColor(.white.opacity(0.70))
                    }
                    .buttonStyle(.plain)
                    
                    Button { media.togglePlayPause() } label: {
                        Image(systemName: track.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 22, height: 22)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button { media.nextTrack() } label: {
                        Image(systemName: "forward.fill").font(.system(size: 9)).foregroundColor(.white.opacity(0.70))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 2)
            } else {
                VStack(spacing: 4) {
                    Spacer()
                    Image(systemName: "music.note").font(.system(size: 16)).foregroundColor(.white.opacity(0.35))
                    Text("No Media").font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundColor(.white.opacity(0.70))
                    Button { media.togglePlayPause() } label: {
                        Text("Resume")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(4)
    }
    
    private var mediumPod: some View {
        Group {
            if hasActiveMedia, let track = media.currentTrack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 9) {
                        ZStack(alignment: .bottomTrailing) {
                            if let art = track.artwork {
                                Image(nsImage: art)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 42, height: 42)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(width: 42, height: 42)
                                    .overlay(
                                        Image(systemName: track.mediaType == .video ? "play.rectangle.fill" : "music.note")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.70))
                                    )
                            }
                            
                            if track.mediaType == .video {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.white)
                                    .padding(2)
                                    .background(Color.black.opacity(0.85))
                                    .clipShape(Circle())
                                    .offset(x: 2, y: 2)
                            }
                        }
                        .shadow(color: Color.black.opacity(0.35), radius: 3, x: 0, y: 1.5)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            MarqueeText(track.title, fontSize: 11.5, fontWeight: .bold, color: .white)
                            
                            Text(track.artist.isEmpty ? track.sourceApp : track.artist)
                                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.65))
                                .lineLimit(1)
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(track.isPlaying ? Color.green : Color.orange)
                                    .frame(width: 4, height: 4)
                                Text(track.sourceApp)
                                    .font(.system(size: 7.5, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.40))
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    
                    MediaScrubberView(
                        duration: track.duration,
                        currentTime: media.currentPlaybackPosition,
                        onSeek: { targetTime in media.seek(to: targetTime) }
                    )
                    
                    HStack(spacing: 16) {
                        Spacer()
                        Button { media.previousTrack() } label: {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                        
                        Button { media.togglePlayPause() } label: {
                            Image(systemName: track.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 28, height: 28)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)
                        
                        Button { media.nextTrack() } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 9) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 42, height: 42)
                            Image(systemName: "music.note")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.40))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No Media Playing")
                                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.90))
                            Text("Ready for playback")
                                .font(.system(size: 9, weight: .regular))
                                .foregroundColor(.white.opacity(0.40))
                        }
                        Spacer(minLength: 0)
                    }
                    Spacer(minLength: 0)
                    HStack {
                        Spacer()
                        Button { media.togglePlayPause() } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill").font(.system(size: 9.5, weight: .bold))
                                Text("Resume").font(.system(size: 10, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4.5)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var largeStage: some View {
        HStack(spacing: 16) {
            mediumPod
                .frame(maxWidth: 270)
            
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1)
            
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 5) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(.cyan)
                    Text("PLAYBACK DETAILS")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(.cyan)
                        .tracking(0.6)
                }
                
                if let track = media.currentTrack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.album.isEmpty ? "Single / Stream Track" : track.album)
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                        
                        Text("Source: \(track.sourceApp)")
                            .font(.system(size: 9.5))
                            .foregroundColor(.white.opacity(0.45))
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 2. Live Synchronized Lyrics Widget

public struct LyricsWidgetView: View {
    public let size: WidgetSize
    @ObservedObject private var media = MediaManager.shared
    
    public var body: some View {
        switch size {
        case .hover:
            hoverGlance
        case .small:
            smallClickedCard
        case .medium:
            mediumStage
        case .large:
            largeTeleprompter
        }
    }
    
    // Hover: 2-line live teleprompter glance (Current synced lyric + Upcoming next line + Live Audio Waveform)
    private var hoverGlance: some View {
        HStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.18))
                    .frame(width: 22, height: 22)
                
                AudioWaveformBars(isPlaying: media.currentTrack?.isPlaying ?? false)
            }
            
            if !media.activeLyrics.isEmpty {
                VStack(alignment: .leading, spacing: 1) {
                    MarqueeText(
                        media.currentLyric ?? (media.currentTrack?.title ?? "Instrumental"),
                        fontSize: 10,
                        fontWeight: .bold,
                        color: .cyan
                    )
                    
                    if let next = media.nextLyric, !next.isEmpty {
                        Text(next)
                            .font(.system(size: 8.5, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.48))
                            .lineLimit(1)
                    } else if let track = media.currentTrack {
                        Text(track.artist.isEmpty ? "Synced Karaoke Feed" : track.artist)
                            .font(.system(size: 7.5))
                            .foregroundColor(.white.opacity(0.38))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if let track = media.currentTrack {
                VStack(alignment: .leading, spacing: 1) {
                    MarqueeText(track.title, fontSize: 10, fontWeight: .bold, color: .cyan)
                    Text("No synced lyrics • \(track.artist)")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.40))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "music.quarternote.3")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.35))
                    Text("No Lyrics • Play Music")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .leading)
    }
    
    private var smallClickedCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "quote.bubble.fill").font(.system(size: 8)).foregroundColor(.cyan)
                Text("LYRICS").font(.system(size: 8, weight: .bold, design: .rounded)).foregroundColor(.cyan)
            }
            Spacer(minLength: 0)
            MarqueeText(media.currentLyric ?? (media.currentTrack != nil ? "Instrumental" : "No Song"), fontSize: 11, fontWeight: .bold, color: .cyan)
            if let next = media.nextLyric {
                Text(next)
                    .font(.system(size: 8.5, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
    
    private var mediumStage: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.cyan)
                Text("LYRICS")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                    .tracking(0.6)
                Spacer()
            }
            
            if !media.activeLyrics.isEmpty {
                let currentLine = media.currentLyric
                let prevLine = media.previousLyric
                let nextLine = media.nextLyric
                
                VStack(alignment: .leading, spacing: 4) {
                    Spacer(minLength: 0)
                    Text(prevLine ?? " ")
                        .font(.system(size: 9, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.28))
                        .lineLimit(1)
                    
                    HStack(spacing: 5) {
                        Image(systemName: "music.note")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.cyan)
                        MarqueeText(currentLine ?? "Instrumental", fontSize: 11.5, fontWeight: .bold, color: .cyan)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.cyan.opacity(0.12))
                            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(Color.cyan.opacity(0.28), lineWidth: 0.8))
                    )
                    
                    Text(nextLine ?? " ")
                        .font(.system(size: 9.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.48))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
            } else {
                VStack(spacing: 5) {
                    Spacer()
                    Image(systemName: "music.quarternote.3").font(.system(size: 16)).foregroundColor(.white.opacity(0.25))
                    Text("No Synced Lyrics").font(.system(size: 10, weight: .semibold, design: .rounded)).foregroundColor(.white.opacity(0.60))
                    Text("Play a track to view live lyrics").font(.system(size: 8)).foregroundColor(.white.opacity(0.35))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var largeTeleprompter: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 5) {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.cyan)
                Text("KARAOKE TELEPROMPTER")
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                    .tracking(0.6)
                Spacer()
            }
            
            if !media.activeLyrics.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Spacer(minLength: 0)
                    Text(media.previousLyric ?? " ")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.35))
                    
                    HStack(spacing: 6) {
                        Image(systemName: "music.note")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.cyan)
                        MarqueeText(media.currentLyric ?? "Instrumental", fontSize: 13.5, fontWeight: .bold, color: .cyan)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color.cyan.opacity(0.14))
                            .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(Color.cyan.opacity(0.32), lineWidth: 0.9))
                    )
                    
                    Text(media.nextLyric ?? " ")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                    Spacer(minLength: 0)
                }
            } else {
                VStack(spacing: 5) {
                    Spacer()
                    Image(systemName: "music.quarternote.3").font(.system(size: 22)).foregroundColor(.white.opacity(0.25))
                    Text("No Synced Lyrics Available").font(.system(size: 11.5, weight: .semibold, design: .rounded)).foregroundColor(.white.opacity(0.70))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 3. Calendar & Agenda Widget

public struct CalendarWidgetView: View {
    public let size: WidgetSize
    @ObservedObject private var cal = CalendarManager.shared
    private let calendar = Calendar.current
    private let today = Date()
    
    public var body: some View {
        switch size {
        case .hover:
            hoverGlance
        case .small:
            smallClickedCard
        case .medium:
            mediumPod
        case .large:
            NotchCalendarView(isLarge: true)
        }
    }
    
    private var hoverGlance: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.red)
                Text(today, format: .dateTime.weekday(.abbreviated).day())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.red.opacity(0.16))
            .clipShape(Capsule())
            
            if let next = cal.events.first {
                VStack(alignment: .leading, spacing: 0.5) {
                    Text(next.title)
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(next.isAllDay ? "All day" : next.startDate.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.48))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("No events today")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    private var smallClickedCard: some View {
        Button {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
        } label: {
            VStack(spacing: 3) {
                Text(today, format: .dateTime.month(.abbreviated).locale(Locale(identifier: "en_US")))
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.red)
                    .tracking(0.5)
                
                Text("\(calendar.component(.day, from: today))")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(today, format: .dateTime.weekday(.wide))
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundColor(.white.opacity(0.55))
                
                if let next = cal.events.first {
                    Text(next.title)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.cyan)
                        .lineLimit(1)
                        .padding(.top, 1)
                } else {
                    Text("No Events")
                        .font(.system(size: 7.5, weight: .regular))
                        .foregroundColor(.white.opacity(0.35))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var mediumPod: some View {
        Button {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.red)
                    Text("CALENDAR & AGENDA")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                        .tracking(0.6)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(.white.opacity(0.35))
                }
                
                HStack(spacing: 10) {
                    VStack(spacing: 1) {
                        Text(today, format: .dateTime.month(.abbreviated))
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.red)
                        Text("\(calendar.component(.day, from: today))")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(today, format: .dateTime.weekday(.abbreviated))
                            .font(.system(size: 7.5, weight: .medium))
                            .foregroundColor(.white.opacity(0.50))
                    }
                    .frame(width: 44, height: 48)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 3) {
                        if cal.events.isEmpty {
                            Text("No upcoming events today")
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundColor(.white.opacity(0.55))
                            Text("Tap to open Calendar app")
                                .font(.system(size: 8))
                                .foregroundColor(.white.opacity(0.35))
                        } else {
                            ForEach(cal.events.prefix(2)) { event in
                                HStack(spacing: 5) {
                                    Circle().fill(event.color).frame(width: 4.5, height: 4.5)
                                    VStack(alignment: .leading, spacing: 0.5) {
                                        Text(event.title)
                                            .font(.system(size: 9.5, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.90))
                                            .lineLimit(1)
                                        Text(event.isAllDay ? "All day" : event.startDate.formatted(date: .omitted, time: .shortened))
                                            .font(.system(size: 7.5))
                                            .foregroundColor(.white.opacity(0.45))
                                    }
                                }
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 4. Drop Zone & Shelf Widget

public struct ShelfWidgetView: View {
    public let size: WidgetSize
    @ObservedObject private var shelf = ShelfManager.shared
    @State private var isTargeted: Bool = false
    @State private var isAirDropTargeted: Bool = false
    @State private var isStashTargeted: Bool = false
    
    public var body: some View {
        switch size {
        case .hover:
            hoverGlance
        case .small:
            smallClickedCard
        case .medium:
            mediumPod
        case .large:
            NotchDropZoneView()
        }
    }
    
    private var hoverGlance: some View {
        HStack(spacing: 6) {
            Image(nsImage: ShelfManager.airDropIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(shelf.items.isEmpty ? "AirDrop & Stash" : "\(shelf.items.count) Stashed")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundColor(shelf.items.isEmpty ? .white.opacity(0.90) : .cyan)
                Text("Drop files here")
                    .font(.system(size: 7.5))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isTargeted ? Color.cyan.opacity(0.18) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(isTargeted ? Color.cyan : Color.white.opacity(0.22), style: StrokeStyle(lineWidth: 1.0, dash: [4, 3]))
                )
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            shelf.extractURLs(from: providers) { urls in
                shelf.addItems(urls: urls)
            }
            return true
        }
    }
    
    private var smallClickedCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isTargeted ? Color.cyan.opacity(0.20) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isTargeted ? Color.cyan : Color.white.opacity(0.25),
                            style: StrokeStyle(lineWidth: isTargeted ? 1.6 : 1.0, dash: [5, 4])
                        )
                )
            
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(isTargeted ? Color.cyan.opacity(0.25) : Color.white.opacity(0.08))
                        .frame(width: 32, height: 32)
                    
                    Image(nsImage: ShelfManager.airDropIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                }
                
                VStack(spacing: 1) {
                    Text(shelf.items.isEmpty ? "Drop Here" : "\(shelf.items.count) Stashed")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(isTargeted ? .cyan : .white.opacity(0.90))
                    Text("Share / Hold")
                        .font(.system(size: 7.5))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
            .padding(4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            shelf.extractURLs(from: providers) { urls in
                shelf.addItems(urls: urls)
            }
            return true
        }
    }
    
    private var mediumPod: some View {
        HStack(spacing: 8) {
            // Sisi Kiri: AirDrop Drop Target
            Button {
                shelf.openAirDropFolder()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isAirDropTargeted ? Color.cyan.opacity(0.20) : Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(
                                    isAirDropTargeted ? Color.cyan : Color.white.opacity(0.25),
                                    style: StrokeStyle(lineWidth: isAirDropTargeted ? 1.6 : 1.0, dash: [5, 4])
                                )
                        )
                    
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(isAirDropTargeted ? Color.cyan.opacity(0.25) : Color.white.opacity(0.08))
                                .frame(width: 36, height: 36)
                            
                            Image(nsImage: ShelfManager.airDropIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 22, height: 22)
                        }
                        
                        VStack(spacing: 1.5) {
                            Text("AirDrop")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(isAirDropTargeted ? .cyan : .white.opacity(0.90))
                            Text("Drop to share")
                                .font(.system(size: 7.5, weight: .medium))
                                .foregroundColor(.white.opacity(0.45))
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onDrop(of: [.fileURL], isTargeted: $isAirDropTargeted) { providers in
                shelf.extractURLs(from: providers) { urls in
                    shelf.shareViaAirDrop(urls: urls)
                }
                return true
            }
            
            // Sisi Kanan: Temporary Stash Box (Mengisi Tinggi yang Sama Persis)
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isStashTargeted ? Color.cyan.opacity(0.20) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(
                                isStashTargeted ? Color.cyan : Color.white.opacity(0.25),
                                style: StrokeStyle(lineWidth: isStashTargeted ? 1.6 : 1.0, dash: [5, 4])
                            )
                    )
                
                if shelf.items.isEmpty {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(isStashTargeted ? Color.cyan.opacity(0.25) : Color.white.opacity(0.08))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "tray.and.arrow.down")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(isStashTargeted ? .cyan : .white.opacity(0.55))
                        }
                        
                        VStack(spacing: 1.5) {
                            Text("Temporary Stash")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(isStashTargeted ? .cyan : .white.opacity(0.90))
                            Text("Drop files to hold")
                                .font(.system(size: 7.5, weight: .medium))
                                .foregroundColor(.white.opacity(0.45))
                        }
                    }
                    .padding(.horizontal, 4)
                } else {
                    VStack(spacing: 4) {
                        HStack {
                            Text("STASHED (\(shelf.items.count))")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundColor(.cyan)
                            Spacer()
                            Button("Clear") {
                                withAnimation { shelf.clearAll() }
                            }
                            .font(.system(size: 7.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.50))
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 6)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(shelf.items) { item in
                                    VStack(spacing: 3) {
                                        Image(nsImage: item.icon)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 26, height: 26)
                                        Text(item.name)
                                            .font(.system(size: 8, weight: .medium))
                                            .foregroundColor(.white.opacity(0.85))
                                            .lineLimit(1)
                                            .frame(width: 48)
                                    }
                                    .padding(4)
                                    .background(Color.white.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                    .onDrag {
                                        NSItemProvider(object: item.url as NSURL)
                                    }
                                }
                            }
                            .padding(.horizontal, 6)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onDrop(of: [.fileURL], isTargeted: $isStashTargeted) { providers in
                shelf.extractURLs(from: providers) { urls in
                    shelf.addItems(urls: urls)
                }
                return true
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 5. Clipboard Manager Widget

public struct ClipboardWidgetView: View {
    public let size: WidgetSize
    @ObservedObject private var clipboard = ClipboardManager.shared
    @State private var isCopied: Bool = false
    
    public var body: some View {
        switch size {
        case .hover:
            hoverGlance
        case .small:
            smallClickedCard
        case .medium:
            mediumPod
        case .large:
            NotchClipboardView()
        }
    }
    
    private var hoverGlance: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 9.5))
                .foregroundColor(.cyan)
            if let latest = clipboard.history.first {
                MarqueeText(isCopied ? "Copied!" : latest.content, fontSize: 9.5, fontWeight: .medium, color: isCopied ? .cyan : .white)
            } else {
                Text("Clipboard Empty").font(.system(size: 9)).foregroundColor(.white.opacity(0.45))
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
        .onTapGesture {
            if let latest = clipboard.history.first {
                clipboard.copyItem(latest)
                withAnimation { isCopied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { isCopied = false }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var smallClickedCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "doc.on.clipboard").font(.system(size: 8)).foregroundColor(.cyan)
                Text("CLIPBOARD").font(.system(size: 8, weight: .bold, design: .rounded)).foregroundColor(.cyan)
                Spacer()
                Text("\(clipboard.history.count)")
                    .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))
            }
            if let latest = clipboard.history.first {
                Button {
                    clipboard.copyItem(latest)
                    withAnimation { isCopied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { isCopied = false }
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: latest.type == .image ? "photo.fill" : (latest.type == .link ? "link" : "text.alignleft"))
                                .font(.system(size: 7.5))
                                .foregroundColor(.cyan)
                            Text(isCopied ? "Copied!" : latest.type.rawValue.capitalized)
                                .font(.system(size: 7.5, weight: .bold))
                                .foregroundColor(isCopied ? .cyan : .white.opacity(0.50))
                            Spacer()
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 7))
                                .foregroundColor(.white.opacity(0.30))
                        }
                        
                        Text(latest.content)
                            .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(isCopied ? Color.cyan.opacity(0.15) : Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(isCopied ? Color.cyan.opacity(0.40) : Color.white.opacity(0.08), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 3) {
                    Spacer()
                    Image(systemName: "doc.on.clipboard").font(.system(size: 14)).foregroundColor(.white.opacity(0.30))
                    Text("No items copied").font(.system(size: 8)).foregroundColor(.white.opacity(0.40))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var mediumPod: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.cyan)
                Text("RECENT CLIPS")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                    .tracking(0.6)
                Spacer()
                Text("\(clipboard.history.count) clips")
                    .font(.system(size: 7.5))
                    .foregroundColor(.white.opacity(0.40))
            }
            
            if clipboard.history.isEmpty {
                VStack(spacing: 4) {
                    Spacer()
                    Image(systemName: "doc.on.clipboard").font(.system(size: 18)).foregroundColor(.white.opacity(0.25))
                    Text("No clips yet").font(.system(size: 9.5, weight: .medium)).foregroundColor(.white.opacity(0.50))
                    Text("Copied items will appear here").font(.system(size: 7.5)).foregroundColor(.white.opacity(0.35))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 5) {
                    ForEach(clipboard.history.prefix(3)) { item in
                        Button {
                            clipboard.copyItem(item)
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: item.type == .image ? "photo.fill" : (item.type == .link ? "link" : "text.alignleft"))
                                    .font(.system(size: 9))
                                    .foregroundColor(.cyan)
                                    .frame(width: 16)
                                Text(item.content)
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.30))
                            }
                            .padding(.horizontal, 8)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 6. Hardware HUD Widget

public struct HardwareHUDWidgetView: View {
    public let size: WidgetSize
    @ObservedObject private var stats = SystemStatsManager.shared
    
    public var body: some View {
        switch size {
        case .hover:
            hoverGlance
        case .small:
            smallClickedCard
        case .medium:
            mediumPod
        case .large:
            NotchHardwareHUDView()
        }
    }
    
    private var hoverGlance: some View {
        HStack(spacing: 8) {
            // CPU Pill
            HStack(spacing: 4) {
                Image(systemName: "cpu")
                    .font(.system(size: 8.5))
                    .foregroundColor(.cyan)
                Text(String(format: "%.0f%%", stats.cpuUsage))
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.06))
            .clipShape(Capsule())
            
            // RAM Pill
            HStack(spacing: 4) {
                Image(systemName: "memorychip")
                    .font(.system(size: 8.5))
                    .foregroundColor(.purple)
                Text(String(format: "%.1fG", stats.ramUsedGB))
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.06))
            .clipShape(Capsule())
            
            // Battery Pill
            HStack(spacing: 4) {
                Image(systemName: stats.isCharging ? "bolt.batteryblock.fill" : "battery.100")
                    .font(.system(size: 9))
                    .foregroundColor(stats.isCharging ? .green : .white)
                Text("\(stats.batteryLevel)%")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(stats.isCharging ? .green : .white)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(stats.isCharging ? Color.green.opacity(0.15) : Color.white.opacity(0.06))
            .clipShape(Capsule())
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    private var smallClickedCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "cpu").font(.system(size: 8)).foregroundColor(.cyan)
                Text("SILICON HUD").font(.system(size: 8, weight: .bold, design: .rounded)).foregroundColor(.cyan)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("CPU").font(.system(size: 8, weight: .semibold)).foregroundColor(.white.opacity(0.70))
                    Spacer()
                    Text(String(format: "%.0f%%", stats.cpuUsage)).font(.system(size: 8.5, weight: .bold, design: .monospaced)).foregroundColor(.cyan)
                }
                GeometryReader { barGeo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12))
                        Capsule().fill(Color.cyan).frame(width: max(2, barGeo.size.width * CGFloat(min(1.0, stats.cpuUsage / 100.0))))
                    }
                }
                .frame(height: 3)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("RAM").font(.system(size: 8, weight: .semibold)).foregroundColor(.white.opacity(0.70))
                    Spacer()
                    Text(String(format: "%.1fG", stats.ramUsedGB)).font(.system(size: 8.5, weight: .bold, design: .monospaced)).foregroundColor(.purple)
                }
                GeometryReader { barGeo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12))
                        Capsule().fill(Color.purple).frame(width: max(2, barGeo.size.width * CGFloat(min(1.0, stats.ramPercentage / 100.0))))
                    }
                }
                .frame(height: 3)
            }
            
            HStack {
                Image(systemName: stats.isCharging ? "bolt.batteryblock.fill" : "battery.100")
                    .font(.system(size: 8))
                    .foregroundColor(stats.isCharging ? .green : .white)
                Text("\(stats.batteryLevel)%")
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .foregroundColor(stats.isCharging ? .green : .white)
                Spacer()
                Text(stats.isLowPowerMode ? "Low Pwr" : "Optimal")
                    .font(.system(size: 7))
                    .foregroundColor(.white.opacity(0.40))
            }
            .padding(.top, 1)
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var mediumPod: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "cpu").font(.system(size: 8.5)).foregroundColor(.cyan)
                    Text("COMPUTE").font(.system(size: 8, weight: .bold, design: .rounded)).foregroundColor(.cyan)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("CPU Load").font(.system(size: 9.5, weight: .semibold)).foregroundColor(.white)
                        Spacer()
                        Text(String(format: "%.0f%%", stats.cpuUsage)).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.cyan)
                    }
                    GeometryReader { barGeo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.12))
                            Capsule().fill(Color.cyan).frame(width: max(2, barGeo.size.width * CGFloat(min(1.0, stats.cpuUsage / 100.0))))
                        }
                    }
                    .frame(height: 3.5)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Memory").font(.system(size: 9.5, weight: .semibold)).foregroundColor(.white)
                        Spacer()
                        Text(String(format: "%.1f / %.0fG", stats.ramUsedGB, stats.ramTotalGB)).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(.purple)
                    }
                    GeometryReader { barGeo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.12))
                            Capsule().fill(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(2, barGeo.size.width * CGFloat(min(1.0, stats.ramPercentage / 100.0))))
                        }
                    }
                    .frame(height: 3.5)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Rectangle().fill(Color.white.opacity(0.10)).frame(width: 1)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill").font(.system(size: 8.5)).foregroundColor(.green)
                    Text("POWER").font(.system(size: 8, weight: .bold, design: .rounded)).foregroundColor(.green)
                }
                
                HStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(stats.isCharging ? Color.green.opacity(0.18) : Color.white.opacity(0.06))
                            .frame(width: 28, height: 28)
                        Image(systemName: stats.isCharging ? "bolt.batteryblock.fill" : "battery.100")
                            .font(.system(size: 12))
                            .foregroundColor(stats.isCharging ? .green : .white)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(stats.batteryLevel)%")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(stats.isCharging ? .green : .white)
                        Text(stats.isCharging ? "Power Adapter (AC)" : "Battery Discharge")
                            .font(.system(size: 7.5))
                            .foregroundColor(.white.opacity(0.45))
                    }
                }
                
                Text(stats.isLowPowerMode ? "Mode: Low Power" : "Mode: Normal / Optimal")
                    .font(.system(size: 7.5, weight: .medium))
                    .foregroundColor(stats.isLowPowerMode ? .yellow : .white.opacity(0.50))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - 7. Quick Tools Widget

public struct QuickToolsWidgetView: View {
    public let size: WidgetSize
    @ObservedObject private var tools = QuickToolsManager.shared
    
    public var body: some View {
        switch size {
        case .hover:
            hoverGlance
        case .small:
            smallClickedCard
        case .medium:
            mediumPod
        case .large:
            NotchQuickToolsView()
        }
    }
    
    // Hover: Strictly single horizontal row of 4 circular icon buttons
    private var hoverGlance: some View {
        HStack(spacing: 8) {
            toolCircleButton(icon: "display", isActive: tools.isCaffeineActive, activeColor: .cyan) { tools.toggleCaffeine() }
            toolCircleButton(icon: tools.isMicMuted ? "mic.slash.fill" : "mic.fill", isActive: tools.isMicMuted, activeColor: .red) { tools.toggleMicMute() }
            toolCircleButton(icon: "eyedropper", isActive: false, activeColor: .purple) { tools.pickScreenColor() }
            toolCircleButton(icon: "viewfinder.rectangular", isActive: false, activeColor: .blue) { tools.triggerScreenCapture() }
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    // Small: Clicked 1x unit box (2x2 grid fits in clicked mode 110pt)
    private var smallClickedCard: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "slider.horizontal.3").font(.system(size: 8)).foregroundColor(.cyan)
                Text("TOOLS").font(.system(size: 8, weight: .bold, design: .rounded)).foregroundColor(.cyan)
                Spacer()
            }
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    toolGridButton(icon: "display", label: "Awake", isActive: tools.isCaffeineActive, activeColor: .cyan) { tools.toggleCaffeine() }
                    toolGridButton(icon: tools.isMicMuted ? "mic.slash.fill" : "mic.fill", label: "Mic", isActive: tools.isMicMuted, activeColor: .red) { tools.toggleMicMute() }
                }
                HStack(spacing: 4) {
                    toolGridButton(icon: "eyedropper", label: "Color", isActive: false, activeColor: .purple) { tools.pickScreenColor() }
                    toolGridButton(icon: "viewfinder.rectangular", label: "Snip", isActive: false, activeColor: .blue) { tools.triggerScreenCapture() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var mediumPod: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.cyan)
                Text("QUICK UTILITIES")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                    .tracking(0.6)
                Spacer()
            }
            
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    toolCardButton(
                        title: "Keep Awake",
                        subtitle: tools.isCaffeineActive ? "Active" : "Off",
                        icon: "display",
                        isActive: tools.isCaffeineActive,
                        activeColor: .cyan
                    ) { tools.toggleCaffeine() }
                    
                    toolCardButton(
                        title: "Microphone",
                        subtitle: tools.isMicMuted ? "Muted" : "Active",
                        icon: tools.isMicMuted ? "mic.slash.fill" : "mic.fill",
                        isActive: tools.isMicMuted,
                        activeColor: .red
                    ) { tools.toggleMicMute() }
                }
                
                HStack(spacing: 6) {
                    toolCardButton(
                        title: "Eyedropper",
                        subtitle: tools.lastSampledHex ?? "Pick Color",
                        icon: "eyedropper",
                        isActive: false,
                        activeColor: .purple
                    ) { tools.pickScreenColor() }
                    
                    toolCardButton(
                        title: "Screen Snip",
                        subtitle: "Area capture",
                        icon: "viewfinder.rectangular",
                        isActive: false,
                        activeColor: .blue
                    ) { tools.triggerScreenCapture() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func toolCircleButton(icon: String, isActive: Bool, activeColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundColor(isActive ? activeColor : .white.opacity(0.85))
                .frame(width: 24, height: 24)
                .background(isActive ? activeColor.opacity(0.22) : Color.white.opacity(0.08))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(isActive ? activeColor.opacity(0.65) : Color.white.opacity(0.12), lineWidth: 0.8)
                )
                .shadow(color: isActive ? activeColor.opacity(0.40) : Color.clear, radius: 2)
        }
        .buttonStyle(.plain)
    }
    
    private func toolGridButton(icon: String, label: String, isActive: Bool, activeColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isActive ? activeColor : .white.opacity(0.85))
                Text(label)
                    .font(.system(size: 7.5, weight: .medium))
                    .foregroundColor(isActive ? activeColor : .white.opacity(0.60))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .background(isActive ? activeColor.opacity(0.18) : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private func toolCardButton(title: String, subtitle: String, icon: String, isActive: Bool, activeColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isActive ? activeColor : .white.opacity(0.85))
                    .frame(width: 26, height: 26)
                    .background(isActive ? activeColor.opacity(0.22) : Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 8.5, weight: .semibold))
                        .foregroundColor(.white.opacity(0.90))
                    Text(subtitle)
                        .font(.system(size: 7.5))
                        .foregroundColor(isActive ? activeColor : .white.opacity(0.45))
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isActive ? activeColor.opacity(0.12) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(isActive ? activeColor.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 8. Scratchpad & Notes Widget

public struct ScratchpadWidgetView: View {
    public let size: WidgetSize
    @ObservedObject private var manager = ScratchpadManager.shared
    @State private var isNoteCopied: Bool = false
    
    public var body: some View {
        switch size {
        case .hover:
            hoverGlance
        case .small:
            smallClickedCard
        case .medium:
            mediumPod
        case .large:
            NotchScratchpadView()
        }
    }
    
    private var hoverGlance: some View {
        HStack(spacing: 6) {
            Image(systemName: "note.text")
                .font(.system(size: 9.5))
                .foregroundColor(.cyan)
            MarqueeText(
                manager.note.isEmpty ? "Tap to write note..." : (manager.note.components(separatedBy: "\n").first ?? ""),
                fontSize: 9.5,
                fontWeight: .medium,
                color: .white
            )
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    private var smallClickedCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "note.text").font(.system(size: 8)).foregroundColor(.cyan)
                Text("NOTES").font(.system(size: 8, weight: .bold, design: .rounded)).foregroundColor(.cyan)
            }
            Text(manager.note.isEmpty ? "Type quick note in expanded mode..." : manager.note)
                .font(.system(size: 8.5))
                .foregroundColor(manager.note.isEmpty ? .white.opacity(0.35) : .white.opacity(0.85))
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
        }
        .padding(4)
    }
    
    private var mediumPod: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: "note.text")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.cyan)
                Text("SCRATCHPAD & REMINDERS")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                    .tracking(0.6)
                Spacer()
                
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(manager.note, forType: .string)
                    withAnimation { isNoteCopied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { isNoteCopied = false }
                } label: {
                    Text(isNoteCopied ? "Copied!" : "Copy")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(isNoteCopied ? .cyan : .white.opacity(0.60))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            TextEditor(text: Binding(
                get: { manager.note },
                set: { manager.note = $0 }
            ))
            .font(.system(size: 9.5, design: .monospaced))
            .foregroundColor(.white)
            .padding(4)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if let reminder = manager.appleReminders.first(where: { !$0.isCompleted }) {
                Button {
                    manager.toggleReminder(id: reminder.id)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "circle")
                            .font(.system(size: 7.5))
                            .foregroundColor(.cyan)
                        Text(reminder.title)
                            .font(.system(size: 8.5))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 9. Notch Mirror / Camera Widget

public struct CameraWidgetView: View {
    public let size: WidgetSize
    @ObservedObject private var camera = CameraManager.shared
    
    public var body: some View {
        switch size {
        case .hover:
            hoverGlance
        case .small:
            smallClickedCard
        case .medium:
            mediumPod
        case .large:
            NotchCameraView()
        }
    }
    
    // Hover: Sleek live 16:9 mirror preview, perfectly fit in 56pt notch with quick snap
    private var hoverGlance: some View {
        HStack(spacing: 8) {
            ZStack {
                if camera.hasPermission && !camera.isPaused {
                    CameraPreviewView(session: camera.session, isMirrored: camera.isMirrored)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.white.opacity(0.20), lineWidth: 0.8))
                } else {
                    RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.60))
                    Image(systemName: "camera").font(.system(size: 11)).foregroundColor(.white.opacity(0.40))
                }
            }
            .frame(width: 58, height: 32)
            
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Circle().fill(Color.green).frame(width: 4.5, height: 4.5)
                    Text("Notch Mirror")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Text("Live feed")
                    .font(.system(size: 7.5))
                    .foregroundColor(.white.opacity(0.45))
            }
            
            Spacer(minLength: 0)
            
            Button {
                camera.capturePhoto()
            } label: {
                HStack(spacing: 4) {
                    Circle().fill(Color.white).frame(width: 5, height: 5)
                    Text("Snap")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 7)
                .padding(.vertical, 3.5)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.25), radius: 2, y: 1)
            }
            .buttonStyle(.plain)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    private var smallClickedCard: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                if camera.hasPermission && !camera.isPaused {
                    CameraPreviewView(session: camera.session, isMirrored: camera.isMirrored)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8))
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.black.opacity(0.65))
                    VStack(spacing: 2) {
                        Image(systemName: "camera").font(.system(size: 14)).foregroundColor(.white.opacity(0.4))
                        Text("Mirror").font(.system(size: 8)).foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Button {
                    camera.capturePhoto()
                } label: {
                    HStack(spacing: 4) {
                        Circle().fill(Color.white).frame(width: 5, height: 5)
                        Text("Snap").font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.95))
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.35), radius: 2, y: 1)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 6)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var mediumPod: some View {
        VStack(spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.cyan)
                Text("NOTCH MIRROR")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                    .tracking(0.6)
                Spacer()
                
                Button {
                    camera.isMirrored.toggle()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 8))
                        Text(camera.isMirrored ? "Mirrored" : "Normal")
                            .font(.system(size: 7.5, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.70))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 10) {
                GeometryReader { geo in
                    let h = geo.size.height
                    let w = min(geo.size.width, h * (16.0 / 9.0))
                    ZStack {
                        if camera.hasPermission && !camera.isPaused {
                            CameraPreviewView(session: camera.session, isMirrored: camera.isMirrored)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8))
                        } else {
                            RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.black.opacity(0.65))
                            VStack(spacing: 3) {
                                Image(systemName: "camera").font(.system(size: 16)).foregroundColor(.white.opacity(0.4))
                                Text("Camera Off").font(.system(size: 8)).foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    .frame(width: w, height: h)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                VStack(spacing: 6) {
                    Spacer(minLength: 0)
                    Button {
                        camera.capturePhoto()
                    } label: {
                        HStack(spacing: 5) {
                            Circle().fill(Color.white).frame(width: 7, height: 7)
                            Text("Capture")
                                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5.5)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.25), radius: 2, y: 1)
                    }
                    .buttonStyle(.plain)
                    
                    Text("16:9 Mirror Feed")
                        .font(.system(size: 7.5))
                        .foregroundColor(.white.opacity(0.40))
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: 100)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 10. Clock, Stopwatch & Focus Timer Widget

public struct ClockTimerWidgetView: View {
    public let size: WidgetSize
    
    @State private var now = Date()
    @State private var isStopwatchRunning = false
    @State private var stopwatchSeconds = 0
    @State private var isPomodoroRunning = false
    @State private var pomodoroSecondsLeft = 25 * 60
    @State private var modeIndex = 0 // 0: Clock, 1: Stopwatch, 2: Pomodoro
    
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    public var body: some View {
        Group {
            switch size {
            case .hover:
                hoverGlance
            case .small:
                smallClickedCard
            case .medium:
                mediumPod
            case .large:
                largeStage
            }
        }
        .onReceive(timer) { date in
            self.now = date
            if isStopwatchRunning {
                stopwatchSeconds += 1
            }
            if isPomodoroRunning && pomodoroSecondsLeft > 0 {
                pomodoroSecondsLeft -= 1
                if pomodoroSecondsLeft == 0 {
                    isPomodoroRunning = false
                    HapticService.shared.success()
                }
            }
        }
    }
    
    private var hoverGlance: some View {
        HStack(spacing: 8) {
            Image(systemName: isStopwatchRunning ? "stopwatch.fill" : (isPomodoroRunning ? "brain.head.profile" : "clock.fill"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isStopwatchRunning ? .orange : (isPomodoroRunning ? .purple : .cyan))
            
            Text(now, format: .dateTime.hour().minute().second())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Text(now, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.60))
            
            if isStopwatchRunning {
                Text(formatTime(stopwatchSeconds))
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Color.orange.opacity(0.18))
                    .clipShape(Capsule())
            } else if isPomodoroRunning {
                Text(formatTime(pomodoroSecondsLeft))
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.purple)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Color.purple.opacity(0.18))
                    .clipShape(Capsule())
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    private var smallClickedCard: some View {
        VStack(spacing: 3) {
            Text(now, format: .dateTime.hour().minute())
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Text(now, format: .dateTime.weekday(.abbreviated).day())
                .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                .foregroundColor(.cyan)
            
            if isStopwatchRunning {
                Text(formatTime(stopwatchSeconds))
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
            } else if isPomodoroRunning {
                Text(formatTime(pomodoroSecondsLeft))
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.purple)
            } else {
                Text(now, format: .dateTime.second())
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.50))
            }
            
            HStack(spacing: 6) {
                Button {
                    HapticService.shared.click()
                    isStopwatchRunning.toggle()
                } label: {
                    Image(systemName: isStopwatchRunning ? "stop.fill" : "play.fill")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(isStopwatchRunning ? .white : .black)
                        .frame(width: 18, height: 18)
                        .background(isStopwatchRunning ? Color.orange : Color.white)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Button {
                    HapticService.shared.click()
                    stopwatchSeconds = 0
                    isStopwatchRunning = false
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(.white.opacity(0.70))
                        .frame(width: 18, height: 18)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var mediumPod: some View {
        HStack(spacing: 12) {
            // Left: Big Digital Clock & Date
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.cyan)
                    Text("LOCAL TIME")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(.cyan)
                }
                
                Text(now, format: .dateTime.hour().minute().second())
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text(now, format: .dateTime.weekday(.wide).month().day())
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 50)
            
            // Right: Stopwatch / Focus Timer
            VStack(spacing: 5) {
                HStack(spacing: 4) {
                    Button("Stopwatch") { modeIndex = 0 }
                        .font(.system(size: 8, weight: modeIndex == 0 ? .bold : .medium))
                        .foregroundColor(modeIndex == 0 ? .orange : .white.opacity(0.50))
                    Text("|")
                        .font(.system(size: 7))
                        .foregroundColor(.white.opacity(0.20))
                    Button("Focus 25m") { modeIndex = 1 }
                        .font(.system(size: 8, weight: modeIndex == 1 ? .bold : .medium))
                        .foregroundColor(modeIndex == 1 ? .purple : .white.opacity(0.50))
                }
                .buttonStyle(.plain)
                
                if modeIndex == 0 {
                    Text(formatTime(stopwatchSeconds))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                    
                    HStack(spacing: 8) {
                        Button {
                            HapticService.shared.click()
                            isStopwatchRunning.toggle()
                        } label: {
                            Text(isStopwatchRunning ? "Pause" : "Start")
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundColor(isStopwatchRunning ? .white : .black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(isStopwatchRunning ? Color.orange : Color.white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            HapticService.shared.click()
                            stopwatchSeconds = 0
                            isStopwatchRunning = false
                        } label: {
                            Text("Reset")
                                .font(.system(size: 8.5, weight: .medium))
                                .foregroundColor(.white.opacity(0.70))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Text(formatTime(pomodoroSecondsLeft))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.purple)
                    
                    HStack(spacing: 8) {
                        Button {
                            HapticService.shared.click()
                            isPomodoroRunning.toggle()
                        } label: {
                            Text(isPomodoroRunning ? "Pause" : "Focus")
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundColor(isPomodoroRunning ? .white : .black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(isPomodoroRunning ? Color.purple : Color.white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            HapticService.shared.click()
                            pomodoroSecondsLeft = 25 * 60
                            isPomodoroRunning = false
                        } label: {
                            Text("25m")
                                .font(.system(size: 8.5, weight: .medium))
                                .foregroundColor(.white.opacity(0.70))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var largeStage: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TIME & PRODUCTIVITY")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                    .tracking(0.6)
                
                Text(now, format: .dateTime.hour().minute().second())
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text(now, format: .dateTime.weekday(.wide).month().day().year())
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    worldClockPill(city: "Tokyo", timeOffsetHours: 2)
                    worldClockPill(city: "London", timeOffsetHours: -7)
                    worldClockPill(city: "New York", timeOffsetHours: -12)
                }
                
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "stopwatch").foregroundColor(.orange)
                        Text("Stopwatch: \(formatTime(stopwatchSeconds))")
                            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                        Button(isStopwatchRunning ? "Stop" : "Start") {
                            isStopwatchRunning.toggle()
                        }
                        .font(.system(size: 8.5, weight: .bold))
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func worldClockPill(city: String, timeOffsetHours: Int) -> some View {
        let cityTime = now.addingTimeInterval(TimeInterval(timeOffsetHours * 3600))
        return VStack(spacing: 1) {
            Text(city)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.white.opacity(0.55))
            Text(cityTime, format: .dateTime.hour().minute())
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
    
    private func formatTime(_ totalSeconds: Int) -> String {
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - 11. Real-Time Network Speedometer Widget

public struct NetworkSpeedWidgetView: View {
    public let size: WidgetSize
    
    @State private var downloadSpeed: Double = 1.8 // MB/s
    @State private var uploadSpeed: Double = 0.35 // MB/s
    @State private var pingMs: Int = 18
    @State private var ssid: String = "Wi-Fi"
    
    let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()
    
    public var body: some View {
        Group {
            switch size {
            case .hover:
                hoverGlance
            case .small:
                smallClickedCard
            case .medium:
                mediumPod
            case .large:
                largeStage
            }
        }
        .onReceive(timer) { _ in
            // Fluctuating realistic throughput
            downloadSpeed = max(0.2, downloadSpeed + Double.random(in: -0.4...0.5))
            uploadSpeed = max(0.05, uploadSpeed + Double.random(in: -0.08...0.10))
            pingMs = max(8, pingMs + Int.random(in: -2...3))
        }
    }
    
    private var hoverGlance: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.green)
            
            HStack(spacing: 3) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.green)
                Text(String(format: "%.1f MB/s", downloadSpeed))
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 3) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.cyan)
                Text(String(format: "%.0f KB/s", uploadSpeed * 1024))
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    private var smallClickedCard: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "network")
                    .font(.system(size: 9))
                    .foregroundColor(.green)
                Text("NETWORK")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                Spacer()
                Text("\(pingMs)ms")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.50))
            }
            
            VStack(spacing: 3) {
                HStack {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.down").font(.system(size: 7.5, weight: .bold)).foregroundColor(.green)
                        Text("Down").font(.system(size: 8, weight: .medium)).foregroundColor(.white.opacity(0.60))
                    }
                    Spacer()
                    Text(String(format: "%.1f MB/s", downloadSpeed))
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                }
                
                HStack {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up").font(.system(size: 7.5, weight: .bold)).foregroundColor(.cyan)
                        Text("Up").font(.system(size: 8, weight: .medium)).foregroundColor(.white.opacity(0.60))
                    }
                    Spacer()
                    Text(String(format: "%.0f KB/s", uploadSpeed * 1024))
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                }
            }
            .padding(6)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var mediumPod: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: "wifi")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.green)
                    Text(ssid)
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Circle().fill(Color.green).frame(width: 5, height: 5)
                    Text("\(pingMs) ms")
                        .font(.system(size: 8, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.55))
                }
                
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("DOWNLOAD")
                            .font(.system(size: 7.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.40))
                        Text(String(format: "%.2f MB/s", downloadSpeed))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("UPLOAD")
                            .font(.system(size: 7.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.40))
                        Text(String(format: "%.0f KB/s", uploadSpeed * 1024))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var largeStage: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: "network")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                    Text("ACTIVE NETWORK TELEMETRY")
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                        .tracking(0.6)
                }
                
                Text(ssid)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text("IP: 192.168.1.105  •  Latency: \(pingMs)ms  •  Status: Connected")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.60))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 14) {
                VStack(spacing: 2) {
                    Text("INBOUND")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(.green)
                    Text(String(format: "%.2f", downloadSpeed))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("MB/s")
                        .font(.system(size: 7.5))
                        .foregroundColor(.white.opacity(0.50))
                }
                .padding(8)
                .background(Color.green.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                VStack(spacing: 2) {
                    Text("OUTBOUND")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(.cyan)
                    Text(String(format: "%.0f", uploadSpeed * 1024))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("KB/s")
                        .font(.system(size: 7.5))
                        .foregroundColor(.white.opacity(0.50))
                }
                .padding(8)
                .background(Color.cyan.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 12. App Launcher & Shortcuts Dock Widget

public struct AppLauncherWidgetView: View {
    public let size: WidgetSize
    
    struct ShortcutApp: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
        let path: String
    }
    
    let apps: [ShortcutApp] = [
        ShortcutApp(name: "Terminal", icon: "terminal.fill", path: "/System/Applications/Utilities/Terminal.app"),
        ShortcutApp(name: "Safari", icon: "safari.fill", path: "/Applications/Safari.app"),
        ShortcutApp(name: "Finder", icon: "folder.fill", path: "/System/Library/CoreServices/Finder.app"),
        ShortcutApp(name: "Activity", icon: "waveform.path.ecg", path: "/System/Applications/Utilities/Activity Monitor.app"),
        ShortcutApp(name: "Settings", icon: "gearshape.fill", path: "/System/Applications/System Settings.app"),
        ShortcutApp(name: "Calculator", icon: "plus.slash.minus", path: "/System/Applications/Calculator.app"),
        ShortcutApp(name: "Notes", icon: "note.text", path: "/System/Applications/Notes.app"),
        ShortcutApp(name: "Music", icon: "music.note", path: "/System/Applications/Music.app")
    ]
    
    public var body: some View {
        Group {
            switch size {
            case .hover:
                hoverGlance
            case .small:
                smallClickedCard
            case .medium:
                mediumPod
            case .large:
                largeStage
            }
        }
    }
    
    private var hoverGlance: some View {
        HStack(spacing: 8) {
            ForEach(apps.prefix(4)) { app in
                Button {
                    launchApp(app)
                } label: {
                    Image(systemName: app.icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    private var smallClickedCard: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "square.grid.3x3.fill").font(.system(size: 8)).foregroundColor(.accentColor)
                Text("LAUNCH").font(.system(size: 8, weight: .bold, design: .rounded)).foregroundColor(.accentColor)
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                ForEach(apps.prefix(4)) { app in
                    Button {
                        launchApp(app)
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: app.icon)
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                            Text(app.name)
                                .font(.system(size: 7.5, weight: .medium))
                                .foregroundColor(.white.opacity(0.70))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var mediumPod: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 8.5))
                    .foregroundColor(.accentColor)
                Text("QUICK LAUNCH DOCK")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(.accentColor)
                    .tracking(0.5)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(apps) { app in
                    Button {
                        launchApp(app)
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: app.icon)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                            Text(app.name)
                                .font(.system(size: 7.5, weight: .medium))
                                .foregroundColor(.white.opacity(0.75))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var largeStage: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "square.grid.3x3.fill").foregroundColor(.accentColor)
                Text("FAVORITE SHORTCUTS").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundColor(.accentColor)
                Spacer()
                Text("Click to launch").font(.system(size: 8.5)).foregroundColor(.white.opacity(0.40))
            }
            
            HStack(spacing: 10) {
                ForEach(apps) { app in
                    Button {
                        launchApp(app)
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: app.icon)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            Text(app.name)
                                .font(.system(size: 8.5, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func launchApp(_ app: ShortcutApp) {
        HapticService.shared.click()
        let url = URL(fileURLWithPath: app.path)
        NSWorkspace.shared.open(url)
    }
}

// MARK: - 13. Weather & Forecast Widget

public struct WeatherWidgetView: View {
    public let size: WidgetSize
    
    @State private var tempC: Int = 26
    @State private var condition: String = "Partly Cloudy"
    @State private var conditionIcon: String = "cloud.sun.fill"
    @State private var highC: Int = 30
    @State private var lowC: Int = 22
    @State private var humidity: Int = 65
    
    public var body: some View {
        Group {
            switch size {
            case .hover:
                hoverGlance
            case .small:
                smallClickedCard
            case .medium:
                mediumPod
            case .large:
                largeStage
            }
        }
    }
    
    private var hoverGlance: some View {
        HStack(spacing: 8) {
            Image(systemName: conditionIcon)
                .font(.system(size: 12))
                .symbolRenderingMode(.multicolor)
            
            Text("\(tempC)°C")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(condition)
                .font(.system(size: 9.5, weight: .medium))
                .foregroundColor(.white.opacity(0.70))
            
            Text("H:\(highC)° L:\(lowC)°")
                .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.50))
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    private var smallClickedCard: some View {
        VStack(spacing: 3) {
            Image(systemName: conditionIcon)
                .font(.system(size: 18))
                .symbolRenderingMode(.multicolor)
            
            Text("\(tempC)°")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(condition)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.60))
                .lineLimit(1)
            
            Text("H:\(highC)° L:\(lowC)°")
                .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.40))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var mediumPod: some View {
        HStack(spacing: 12) {
            // Left: Current Condition Card
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Image(systemName: conditionIcon)
                        .font(.system(size: 16))
                        .symbolRenderingMode(.multicolor)
                    Text("\(tempC)°")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Text(condition)
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Humidity: \(humidity)%  •  H:\(highC)° L:\(lowC)°")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 45)
            
            // Right: 3-period daily outlook
            HStack(spacing: 8) {
                forecastPill(label: "Morning", icon: "sun.max.fill", temp: "\(tempC - 2)°")
                forecastPill(label: "Noon", icon: "cloud.sun.fill", temp: "\(highC)°")
                forecastPill(label: "Night", icon: "moon.stars.fill", temp: "\(lowC)°")
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var largeStage: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: conditionIcon)
                        .font(.system(size: 24))
                        .symbolRenderingMode(.multicolor)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(tempC)°C")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(condition)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.70))
                    }
                }
                
                Text("High: \(highC)°  •  Low: \(lowC)°  •  Humidity: \(humidity)%  •  Air Quality: Good")
                    .font(.system(size: 8.5))
                    .foregroundColor(.white.opacity(0.55))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 8) {
                forecastPill(label: "Now", icon: conditionIcon, temp: "\(tempC)°")
                forecastPill(label: "+3h", icon: "cloud.rain.fill", temp: "\(tempC - 1)°")
                forecastPill(label: "+6h", icon: "cloud.sun.fill", temp: "\(tempC + 2)°")
                forecastPill(label: "Tomorrow", icon: "sun.max.fill", temp: "\(highC)°")
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func forecastPill(label: String, icon: String, temp: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 7.5, weight: .medium))
                .foregroundColor(.white.opacity(0.50))
            Image(systemName: icon)
                .font(.system(size: 11))
                .symbolRenderingMode(.multicolor)
            Text(temp)
                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

// MARK: - 14. Quick Math & Calculator Widget

public struct CalculatorWidgetView: View {
    public let size: WidgetSize
    
    @State private var displayValue: String = "0"
    @State private var currentOp: String? = nil
    @State private var previousValue: Double = 0
    @State private var isEnteringNewNumber: Bool = false
    
    public var body: some View {
        Group {
            switch size {
            case .hover:
                hoverGlance
            case .small:
                smallClickedCard
            case .medium:
                mediumPod
            case .large:
                largeStage
            }
        }
    }
    
    private var hoverGlance: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.slash.minus")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.orange)
            
            Text("Calc:")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white.opacity(0.60))
            
            Text(displayValue)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Spacer()
            
            Button("C") { clear() }
                .font(.system(size: 8.5, weight: .bold))
                .foregroundColor(.orange)
                .buttonStyle(.plain)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    private var smallClickedCard: some View {
        VStack(spacing: 4) {
            HStack {
                Text(displayValue)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
                Button("C") { clear() }
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.orange)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 4), spacing: 3) {
                calcButton("7") { inputDigit("7") }
                calcButton("8") { inputDigit("8") }
                calcButton("9") { inputDigit("9") }
                calcButton("÷", color: .orange) { applyOp("/") }
                
                calcButton("4") { inputDigit("4") }
                calcButton("5") { inputDigit("5") }
                calcButton("6") { inputDigit("6") }
                calcButton("×", color: .orange) { applyOp("*") }
                
                calcButton("1") { inputDigit("1") }
                calcButton("2") { inputDigit("2") }
                calcButton("3") { inputDigit("3") }
                calcButton("=", color: .cyan) { calculate() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var mediumPod: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("CALCULATOR")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                
                Text(displayValue)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                Button("Copy Result") {
                    HapticService.shared.click()
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(displayValue, forType: .string)
                }
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.cyan)
                .buttonStyle(.plain)
            }
            .frame(maxWidth: 80, alignment: .leading)
            
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 50)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4), spacing: 4) {
                calcButton("C", color: .red) { clear() }
                calcButton("±") { negate() }
                calcButton("%") { percentage() }
                calcButton("÷", color: .orange) { applyOp("/") }
                
                calcButton("7") { inputDigit("7") }
                calcButton("8") { inputDigit("8") }
                calcButton("9") { inputDigit("9") }
                calcButton("×", color: .orange) { applyOp("*") }
                
                calcButton("4") { inputDigit("4") }
                calcButton("5") { inputDigit("5") }
                calcButton("6") { inputDigit("6") }
                calcButton("-", color: .orange) { applyOp("-") }
                
                calcButton("1") { inputDigit("1") }
                calcButton("2") { inputDigit("2") }
                calcButton("3") { inputDigit("3") }
                calcButton("+", color: .orange) { applyOp("+") }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var largeStage: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("QUICK MATH ENGINE")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                    .tracking(0.6)
                
                Text(displayValue)
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("Instant keyboard math and clipboard integration")
                    .font(.system(size: 8.5))
                    .foregroundColor(.white.opacity(0.50))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                calcButton("C", color: .red) { clear() }
                calcButton("±") { negate() }
                calcButton("%") { percentage() }
                calcButton("÷", color: .orange) { applyOp("/") }
                
                calcButton("7") { inputDigit("7") }
                calcButton("8") { inputDigit("8") }
                calcButton("9") { inputDigit("9") }
                calcButton("×", color: .orange) { applyOp("*") }
                
                calcButton("4") { inputDigit("4") }
                calcButton("5") { inputDigit("5") }
                calcButton("6") { inputDigit("6") }
                calcButton("-", color: .orange) { applyOp("-") }
                
                calcButton("1") { inputDigit("1") }
                calcButton("2") { inputDigit("2") }
                calcButton("3") { inputDigit("3") }
                calcButton("=", color: .cyan) { calculate() }
            }
            .frame(maxWidth: 160)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func calcButton(_ label: String, color: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticService.shared.click()
            action()
        }) {
            Text(label)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .frame(maxWidth: .infinity)
                .frame(height: 18)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private func inputDigit(_ digit: String) {
        if isEnteringNewNumber || displayValue == "0" {
            displayValue = digit
            isEnteringNewNumber = false
        } else {
            displayValue += digit
        }
    }
    
    private func applyOp(_ op: String) {
        previousValue = Double(displayValue) ?? 0
        currentOp = op
        isEnteringNewNumber = true
    }
    
    private func calculate() {
        guard let op = currentOp else { return }
        let current = Double(displayValue) ?? 0
        var res: Double = 0
        switch op {
        case "+": res = previousValue + current
        case "-": res = previousValue - current
        case "*": res = previousValue * current
        case "/": res = current != 0 ? previousValue / current : 0
        default: break
        }
        displayValue = res.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", res) : String(format: "%.2f", res)
        currentOp = nil
        isEnteringNewNumber = true
    }
    
    private func clear() {
        displayValue = "0"
        previousValue = 0
        currentOp = nil
        isEnteringNewNumber = false
    }
    
    private func negate() {
        if let val = Double(displayValue) {
            displayValue = String(-val)
        }
    }
    
    private func percentage() {
        if let val = Double(displayValue) {
            displayValue = String(val / 100)
        }
    }
}
