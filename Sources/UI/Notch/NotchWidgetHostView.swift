import SwiftUI
import AppKit
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
            smallAdaptive
        case .medium:
            mediumPod
        case .large:
            largeStage
        }
    }
    
    private var smallAdaptive: some View {
        GeometryReader { geo in
            if geo.size.height < 65 {
                // Compact horizontal glance for hover bar (56pt)
                HStack(spacing: 6) {
                    if hasActiveMedia, let track = media.currentTrack {
                        if let art = track.artwork {
                            Image(nsImage: art)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 22, height: 22)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        } else {
                            Image(systemName: track.mediaType == .video ? "play.rectangle.fill" : "music.note")
                                .font(.system(size: 10))
                                .foregroundColor(.cyan)
                        }
                        
                        VStack(alignment: .leading, spacing: 0.5) {
                            MarqueeText(track.title, fontSize: 9.5, fontWeight: .bold, color: .white)
                            Text(track.artist.isEmpty ? track.sourceApp : track.artist)
                                .font(.system(size: 8))
                                .foregroundColor(.white.opacity(0.55))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: 72, alignment: .leading)
                        
                        Button {
                            media.togglePlayPause()
                        } label: {
                            Image(systemName: track.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 18, height: 18)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "music.note")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.40))
                            Text("No Media")
                                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.50))
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                // Vertical 1x unit tile for clicked grid (Trio/Quad)
                VStack(spacing: 4) {
                    if hasActiveMedia, let track = media.currentTrack {
                        if let art = track.artwork {
                            Image(nsImage: art)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 34, height: 34)
                                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Color.white.opacity(0.15), lineWidth: 0.6))
                        } else {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Image(systemName: track.mediaType == .video ? "play.rectangle.fill" : "music.note")
                                        .font(.system(size: 14))
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
                                    .frame(width: 20, height: 20)
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
        }
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
    }
}

// MARK: - 2. Live Synchronized Lyrics Widget

public struct LyricsWidgetView: View {
    public let size: WidgetSize
    @ObservedObject private var media = MediaManager.shared
    
    public var body: some View {
        switch size {
        case .small:
            smallAdaptive
        case .medium:
            mediumStage
        case .large:
            largeTeleprompter
        }
    }
    
    private var smallAdaptive: some View {
        GeometryReader { geo in
            if geo.size.height < 65 {
                HStack(spacing: 5) {
                    Image(systemName: "music.note")
                        .font(.system(size: 8.5))
                        .foregroundColor(.cyan)
                    MarqueeText(
                        media.currentLyric ?? (media.currentTrack?.title ?? "No lyrics"),
                        fontSize: 9.5,
                        fontWeight: .semibold,
                        color: .cyan
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
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
        }
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
        case .small:
            smallAdaptive
        case .medium:
            mediumPod
        case .large:
            NotchCalendarView(isLarge: true)
        }
    }
    
    private var smallAdaptive: some View {
        GeometryReader { geo in
            if geo.size.height < 65 {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.red)
                    Text(today, format: .dateTime.weekday(.abbreviated).day())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    if let next = cal.events.first {
                        Text("• " + next.title)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.60))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
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
        }
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
                    // Big date badge
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
                    
                    // Agenda list
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
    
    public var body: some View {
        switch size {
        case .small:
            smallAdaptive
        case .medium:
            mediumPod
        case .large:
            NotchDropZoneView()
        }
    }
    
    private var smallAdaptive: some View {
        GeometryReader { geo in
            if geo.size.height < 65 {
                HStack(spacing: 5) {
                    Image(nsImage: ShelfManager.airDropIcon)
                        .resizable()
                        .frame(width: 14, height: 14)
                    Text(shelf.items.isEmpty ? "Drop Stash" : "\(shelf.items.count) Stashed")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(shelf.items.isEmpty ? .white.opacity(0.70) : .cyan)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isTargeted ? Color.cyan.opacity(0.20) : Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(
                                    isTargeted ? Color.cyan : Color.white.opacity(0.30),
                                    style: StrokeStyle(lineWidth: isTargeted ? 1.6 : 1.0, dash: [4, 3])
                                )
                        )
                    
                    VStack(spacing: 3) {
                        Image(nsImage: ShelfManager.airDropIcon)
                            .resizable()
                            .frame(width: 22, height: 22)
                        Text(shelf.items.isEmpty ? "Drop Here" : "\(shelf.items.count) Items")
                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                            .foregroundColor(isTargeted ? .cyan : .white.opacity(0.85))
                    }
                }
                .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                    shelf.extractURLs(from: providers) { urls in
                        shelf.addItems(urls: urls)
                    }
                    return true
                }
            }
        }
    }
    
    private var mediumPod: some View {
        HStack(spacing: 8) {
            // AirDrop square box
            Button {
                shelf.openAirDropFolder()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.30), style: StrokeStyle(lineWidth: 1.0, dash: [4, 3]))
                        )
                    
                    VStack(spacing: 3) {
                        Image(nsImage: ShelfManager.airDropIcon)
                            .resizable()
                            .frame(width: 22, height: 22)
                        Text("AirDrop")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                .frame(width: 62, height: 62)
            }
            .buttonStyle(.plain)
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                shelf.extractURLs(from: providers) { urls in
                    shelf.shareViaAirDrop(urls: urls)
                }
                return true
            }
            
            // Temporary shelf tray
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.25), style: StrokeStyle(lineWidth: 1.0, dash: [4, 3]))
                    )
                
                if shelf.items.isEmpty {
                    VStack(spacing: 2) {
                        Image(systemName: "tray.and.arrow.down")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.40))
                        Text("Temporary Stash")
                            .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.65))
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(shelf.items) { item in
                                VStack(spacing: 2) {
                                    Image(nsImage: item.icon)
                                        .resizable()
                                        .frame(width: 22, height: 22)
                                    Text(item.name)
                                        .font(.system(size: 7.5))
                                        .foregroundColor(.white.opacity(0.80))
                                        .lineLimit(1)
                                        .frame(width: 44)
                                }
                            }
                        }
                        .padding(4)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                shelf.extractURLs(from: providers) { urls in
                    shelf.addItems(urls: urls)
                }
                return true
            }
        }
    }
}

// MARK: - 5. Clipboard Manager Widget

public struct ClipboardWidgetView: View {
    public let size: WidgetSize
    @ObservedObject private var clipboard = ClipboardManager.shared
    @State private var isCopied: Bool = false
    
    public var body: some View {
        switch size {
        case .small:
            smallAdaptive
        case .medium:
            mediumPod
        case .large:
            NotchClipboardView()
        }
    }
    
    private var smallAdaptive: some View {
        GeometryReader { geo in
            if geo.size.height < 65 {
                HStack(spacing: 5) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 9.5))
                        .foregroundColor(.cyan)
                    if let latest = clipboard.history.first {
                        MarqueeText(latest.content, fontSize: 9.5, fontWeight: .medium, color: .white)
                    } else {
                        Text("Clipboard Empty").font(.system(size: 9)).foregroundColor(.white.opacity(0.45))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard").font(.system(size: 8)).foregroundColor(.cyan)
                        Text("CLIPBOARD").font(.system(size: 8, weight: .bold, design: .rounded)).foregroundColor(.cyan)
                    }
                    if let latest = clipboard.history.first {
                        Button {
                            clipboard.copyItem(latest)
                            withAnimation { isCopied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { isCopied = false }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isCopied ? "Copied!" : latest.content)
                                    .font(.system(size: 9, weight: isCopied ? .bold : .regular, design: .monospaced))
                                    .foregroundColor(isCopied ? .cyan : .white.opacity(0.85))
                                    .lineLimit(3)
                            }
                            .padding(5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("No items copied").font(.system(size: 8.5)).foregroundColor(.white.opacity(0.40))
                    }
                    Spacer(minLength: 0)
                }
                .padding(4)
            }
        }
    }
    
    private var mediumPod: some View {
        VStack(alignment: .leading, spacing: 5) {
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
                VStack(spacing: 3) {
                    Spacer()
                    Image(systemName: "doc.on.clipboard").font(.system(size: 16)).foregroundColor(.white.opacity(0.30))
                    Text("No clips yet").font(.system(size: 9.5, weight: .medium)).foregroundColor(.white.opacity(0.50))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 4) {
                    ForEach(clipboard.history.prefix(3)) { item in
                        Button {
                            clipboard.copyItem(item)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: item.type == .image ? "photo" : (item.type == .link ? "link" : "text.alignleft"))
                                    .font(.system(size: 8.5))
                                    .foregroundColor(.cyan)
                                Text(item.content)
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 7.5))
                                    .foregroundColor(.white.opacity(0.35))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3.5)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - 6. Hardware HUD Widget

public struct HardwareHUDWidgetView: View {
    public let size: WidgetSize
    @ObservedObject private var stats = SystemStatsManager.shared
    
    public var body: some View {
        switch size {
        case .small:
            smallAdaptive
        case .medium:
            mediumPod
        case .large:
            NotchHardwareHUDView()
        }
    }
    
    private var smallAdaptive: some View {
        GeometryReader { geo in
            if geo.size.height < 65 {
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "cpu").font(.system(size: 8.5)).foregroundColor(.cyan)
                        Text(String(format: "%.0f%%", stats.cpuUsage)).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(.cyan)
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "memorychip").font(.system(size: 8.5)).foregroundColor(.purple)
                        Text(String(format: "%.1fG", stats.ramUsedGB)).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(.purple)
                    }
                    HStack(spacing: 3) {
                        Image(systemName: stats.isCharging ? "bolt.fill" : "battery.100").font(.system(size: 8.5)).foregroundColor(.green)
                        Text("\(stats.batteryLevel)%").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(.green)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "cpu").font(.system(size: 8)).foregroundColor(.cyan)
                        Text("SILICON HUD").font(.system(size: 8, weight: .bold, design: .rounded)).foregroundColor(.cyan)
                    }
                    
                    // CPU Row
                    VStack(alignment: .leading, spacing: 1) {
                        HStack {
                            Text("CPU").font(.system(size: 8, weight: .semibold)).foregroundColor(.white.opacity(0.70))
                            Spacer()
                            Text(String(format: "%.0f%%", stats.cpuUsage)).font(.system(size: 8.5, weight: .bold, design: .monospaced)).foregroundColor(.cyan)
                        }
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.12)).frame(height: 3)
                            Capsule().fill(Color.cyan).frame(width: max(2, 60.0 * CGFloat(min(1.0, stats.cpuUsage / 100.0))), height: 3)
                        }
                    }
                    
                    // RAM Row
                    VStack(alignment: .leading, spacing: 1) {
                        HStack {
                            Text("RAM").font(.system(size: 8, weight: .semibold)).foregroundColor(.white.opacity(0.70))
                            Spacer()
                            Text(String(format: "%.1fG", stats.ramUsedGB)).font(.system(size: 8.5, weight: .bold, design: .monospaced)).foregroundColor(.purple)
                        }
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.12)).frame(height: 3)
                            Capsule().fill(Color.purple).frame(width: max(2, 60.0 * CGFloat(min(1.0, stats.ramPercentage / 100.0))), height: 3)
                        }
                    }
                    
                    // Battery Row
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
        }
    }
    
    private var mediumPod: some View {
        HStack(spacing: 12) {
            // Left: CPU & RAM
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "cpu").font(.system(size: 8.5)).foregroundColor(.cyan)
                    Text("COMPUTE").font(.system(size: 8, weight: .bold, design: .rounded)).foregroundColor(.cyan)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("CPU Load").font(.system(size: 9.5, weight: .semibold)).foregroundColor(.white)
                        Spacer()
                        Text(String(format: "%.0f%%", stats.cpuUsage)).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.cyan)
                    }
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12)).frame(height: 3.5)
                        Capsule().fill(Color.cyan).frame(width: max(2, 85.0 * CGFloat(min(1.0, stats.cpuUsage / 100.0))), height: 3.5)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Memory").font(.system(size: 9.5, weight: .semibold)).foregroundColor(.white)
                        Spacer()
                        Text(String(format: "%.1f / %.0fG", stats.ramUsedGB, stats.ramTotalGB)).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(.purple)
                    }
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12)).frame(height: 3.5)
                        Capsule().fill(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(2, 85.0 * CGFloat(min(1.0, stats.ramPercentage / 100.0))), height: 3.5)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Rectangle().fill(Color.white.opacity(0.10)).frame(width: 1)
            
            // Right: Battery & Power
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
        case .small:
            smallAdaptive
        case .medium:
            mediumPod
        case .large:
            NotchQuickToolsView()
        }
    }
    
    private var smallAdaptive: some View {
        GeometryReader { geo in
            if geo.size.height < 65 {
                HStack(spacing: 8) {
                    toolCircleButton(icon: "display", isActive: tools.isCaffeineActive, activeColor: .cyan) { tools.toggleCaffeine() }
                    toolCircleButton(icon: tools.isMicMuted ? "mic.slash.fill" : "mic.fill", isActive: tools.isMicMuted, activeColor: .red) { tools.toggleMicMute() }
                    toolCircleButton(icon: "eyedropper", isActive: false, activeColor: .purple) { tools.pickScreenColor() }
                    toolCircleButton(icon: "viewfinder.rectangular", isActive: false, activeColor: .blue) { tools.triggerScreenCapture() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                VStack(spacing: 5) {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3").font(.system(size: 8)).foregroundColor(.cyan)
                        Text("TOOLS").font(.system(size: 8, weight: .bold, design: .rounded)).foregroundColor(.cyan)
                    }
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        toolGridButton(icon: "display", label: "Awake", isActive: tools.isCaffeineActive, activeColor: .cyan) { tools.toggleCaffeine() }
                        toolGridButton(icon: tools.isMicMuted ? "mic.slash.fill" : "mic.fill", label: "Mic", isActive: tools.isMicMuted, activeColor: .red) { tools.toggleMicMute() }
                        toolGridButton(icon: "eyedropper", label: "Color", isActive: false, activeColor: .purple) { tools.pickScreenColor() }
                        toolGridButton(icon: "viewfinder.rectangular", label: "Snip", isActive: false, activeColor: .blue) { tools.triggerScreenCapture() }
                    }
                }
                .padding(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
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
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
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
    }
    
    private func toolCircleButton(icon: String, isActive: Bool, activeColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundColor(isActive ? activeColor : .white.opacity(0.80))
                .frame(width: 22, height: 22)
                .background(isActive ? activeColor.opacity(0.20) : Color.white.opacity(0.08))
                .clipShape(Circle())
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
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(isActive ? activeColor.opacity(0.18) : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private func toolCardButton(title: String, subtitle: String, icon: String, isActive: Bool, activeColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isActive ? activeColor : .white.opacity(0.85))
                    .frame(width: 24, height: 24)
                    .background(isActive ? activeColor.opacity(0.22) : Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                
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
            .padding(5)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
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
        case .small:
            smallAdaptive
        case .medium:
            mediumPod
        case .large:
            NotchScratchpadView()
        }
    }
    
    private var smallAdaptive: some View {
        GeometryReader { geo in
            if geo.size.height < 65 {
                HStack(spacing: 5) {
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
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
        }
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
            
            // Note Editor Area
            TextEditor(text: Binding(
                get: { manager.note },
                set: { manager.note = $0 }
            ))
            .font(.system(size: 9.5, design: .monospaced))
            .foregroundColor(.white)
            .padding(4)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .frame(maxHeight: 48)
            
            // Next reminder preview
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
    }
}

// MARK: - 9. Notch Mirror / Camera Widget

public struct CameraWidgetView: View {
    public let size: WidgetSize
    @ObservedObject private var camera = CameraManager.shared
    
    public var body: some View {
        switch size {
        case .small:
            smallAdaptive
        case .medium:
            mediumPod
        case .large:
            NotchCameraView()
        }
    }
    
    private var smallAdaptive: some View {
        GeometryReader { geo in
            if geo.size.height < 65 {
                HStack(spacing: 6) {
                    ZStack {
                        if camera.hasPermission && !camera.isPaused {
                            CameraPreviewView(session: camera.session, isMirrored: camera.isMirrored)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 4).fill(Color.black.opacity(0.6))
                            Image(systemName: "camera").font(.system(size: 9)).foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .frame(width: 32, height: 20)
                    
                    Text("Mirror").font(.system(size: 9, weight: .semibold, design: .rounded)).foregroundColor(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                VStack(spacing: 4) {
                    ZStack {
                        if camera.hasPermission && !camera.isPaused {
                            CameraPreviewView(session: camera.session, isMirrored: camera.isMirrored)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.6))
                            Image(systemName: "camera").font(.system(size: 13)).foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .frame(width: 64, height: 48)
                    
                    Button {
                        camera.capturePhoto()
                    } label: {
                        HStack(spacing: 3) {
                            Circle().fill(Color.white).frame(width: 6, height: 6)
                            Text("Snap").font(.system(size: 8, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(Color.white)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private var mediumPod: some View {
        VStack(spacing: 5) {
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
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.system(size: 8.5))
                        .foregroundColor(.white.opacity(0.60))
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 12) {
                ZStack {
                    if camera.hasPermission && !camera.isPaused {
                        CameraPreviewView(session: camera.session, isMirrored: camera.isMirrored)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8))
                    } else {
                        RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.6))
                        Image(systemName: "camera").font(.system(size: 18)).foregroundColor(.white.opacity(0.4))
                    }
                }
                .frame(width: 110, height: 62)
                
                VStack(spacing: 6) {
                    Button {
                        camera.capturePhoto()
                    } label: {
                        HStack(spacing: 4) {
                            Circle().fill(Color.white).frame(width: 8, height: 8)
                            Text("Capture").font(.system(size: 9.5, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    
                    Text("16:9 Mirror Feed")
                        .font(.system(size: 7.5))
                        .foregroundColor(.white.opacity(0.40))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
