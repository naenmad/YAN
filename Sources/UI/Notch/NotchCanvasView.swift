import SwiftUI
import AppKit

public struct NotchCanvasView: View {
    @ObservedObject var store: NotchSettingsStore = .shared
    @ObservedObject var media: MediaManager = .shared
    
    @State private var isHovered: Bool = false
    @State private var isExpanded: Bool = false
    
    private var hasActiveMedia: Bool {
        return media.currentTrack != nil && media.currentTrack!.isValid
    }
    
    // Dimensi adaptif: Resting (200x30) -> Hover Glance (500x56) -> Clicked Large Dashboard (640x205)
    private var currentWidth: CGFloat {
        let base = CGFloat(store.preferences.width)
        if isExpanded {
            return 640.0
        }
        if isHovered && store.preferences.expandOnHover {
            return 500.0
        }
        return hasActiveMedia ? max(base, 220.0) : base
    }
    
    private var currentHeight: CGFloat {
        let base = CGFloat(store.preferences.height)
        if isExpanded {
            return 205.0
        }
        if isHovered && store.preferences.expandOnHover {
            return 56.0
        }
        return base
    }
    
    private var activeCornerRadius: CGFloat {
        let base = CGFloat(store.preferences.cornerRadius)
        if isExpanded {
            return 26.0
        }
        if isHovered && store.preferences.expandOnHover {
            return 16.0
        }
        return base
    }
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                // 1. Solid Black Notch Body
                NotchShape(
                    cornerRadius: activeCornerRadius,
                    earRadius: CGFloat(store.preferences.earRadius)
                )
                .fill(Color.black)
                .shadow(
                    color: Color.black.opacity(isExpanded ? 0.65 : (isHovered ? 0.40 : 0.0)),
                    radius: isExpanded ? 22 : 12,
                    x: 0,
                    y: isExpanded ? 10 : 5
                )
                
                // 2. Faint Rim Hint Outline
                if store.preferences.showOutline {
                    NotchBorderShape(
                        cornerRadius: activeCornerRadius,
                        earRadius: CGFloat(store.preferences.earRadius)
                    )
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(store.preferences.outlineOpacity),
                                Color.white.opacity(store.preferences.outlineOpacity * 0.45),
                                Color.white.opacity(store.preferences.outlineOpacity)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
                }
                
                // 3. Resting State: Mini Media Glance
                if !isExpanded && !isHovered && hasActiveMedia, let track = media.currentTrack {
                    HStack(spacing: 8) {
                        if let art = track.artwork {
                            Image(nsImage: art)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 16, height: 16)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        } else {
                            Image(systemName: track.mediaType == .video ? "play.rectangle.fill" : "music.note")
                                .font(.system(size: 10))
                                .foregroundColor(.accentColor)
                        }
                        
                        Text(track.title)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(1)
                            .frame(maxWidth: 140, alignment: .leading)
                        
                        Spacer()
                        
                        Circle()
                            .fill(track.isPlaying ? Color.green : Color.orange)
                            .frame(width: 4, height: 4)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 7)
                    .transition(.opacity)
                }
                
                // 4. Large Dashboard State (Saat Diklik / Enlarged 640x205)
                if isExpanded {
                    largeDashboardContent
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                } else if isHovered && store.preferences.expandOnHover {
                    // 5. Compact Pod (Saat Hover 500x56)
                    compactHoverContent
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .frame(width: currentWidth, height: currentHeight)
            .contentShape(
                NotchShape(
                    cornerRadius: activeCornerRadius,
                    earRadius: CGFloat(store.preferences.earRadius)
                )
            )
            .onHover { hovering in
                guard store.preferences.expandOnHover else { return }
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    isHovered = hovering
                }
            }
            .onTapGesture(count: 2) {
                SettingsWindowController.shared.show()
            }
            .onTapGesture(count: 1) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
            }
            .contextMenu {
                Button(isExpanded ? "Collapse Notch" : "Enlarge Notch") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        isExpanded.toggle()
                    }
                }
                Divider()
                Button("Open Calendar") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
                }
                Divider()
                Button("Settings...") {
                    SettingsWindowController.shared.show()
                }
                Divider()
                Button("Reset to Defaults") {
                    store.resetToDefaults()
                }
                Divider()
                Button("Quit YAN") {
                    NSApplication.shared.terminate(nil)
                }
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)) { _ in
            isHovered = false
            isExpanded = false
        }
    }
    
    // MARK: - Large Dashboard Content (Saat Diklik / Enlarged 640x205)
    
    @ViewBuilder
    private var largeDashboardContent: some View {
        HStack(spacing: 16) {
            // SISI KIRI: Media Player + Dedicated Lyrics Card (Lebar ~330pt)
            VStack(alignment: .leading, spacing: 10) {
                // Top: Media Player Controls & Scrubber
                topMediaSection
                
                // Bottom: DEDICATED LYRICS AREA (Sesuai Permintaan User)
                dedicatedLyricsCard
            }
            .frame(width: 330)
            
            // DIVIDER
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1, height: 175)
            
            // SISI KANAN: Calendar Month + Schedule / Jadwal (Lebar ~260pt)
            ZStack(alignment: .topTrailing) {
                NotchCalendarView(isLarge: true)
                    .frame(width: 255)
                
                // Tombol collapse kecil di pojok kanan atas
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        isExpanded = false
                    }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(.white.opacity(0.50))
                        .frame(width: 18, height: 18)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: -4)
                .help("Collapse Notch")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }
    
    // MARK: - Top Media Section (Di Atas Lirik)
    
    @ViewBuilder
    private var topMediaSection: some View {
        if hasActiveMedia, let track = media.currentTrack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    // Artwork / Video Thumbnail (Tanpa gradasi aneh)
                    ZStack(alignment: .bottomTrailing) {
                        if let art = track.artwork {
                            Image(nsImage: art)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: track.mediaType == .video ? "play.rectangle.fill" : "music.note")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white.opacity(0.80))
                                )
                        }
                        
                        if track.mediaType == .video {
                            Image(systemName: "video.fill")
                                .font(.system(size: 7))
                                .foregroundColor(.white)
                                .padding(2.5)
                                .background(Color.black.opacity(0.85))
                                .clipShape(Circle())
                                .offset(x: 2, y: 2)
                        }
                    }
                    .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(track.artist.isEmpty ? track.sourceApp : track.artist)
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundColor(.white.opacity(0.65))
                            .lineLimit(1)
                        
                        Text(track.sourceApp)
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundColor(.white.opacity(0.40))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Controls: Prev, Play/Pause, Next
                    HStack(spacing: 6) {
                        Button {
                            media.previousTrack()
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            media.togglePlayPause()
                        } label: {
                            Image(systemName: track.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.black)
                                .frame(width: 26, height: 26)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            media.nextTrack()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Playback Scrubber Bar
                VStack(spacing: 2) {
                    GeometryReader { geo in
                        let progress = track.duration > 0 ? min(1.0, max(0.0, media.currentPlaybackPosition / track.duration)) : 0.0
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 2.5)
                            Capsule()
                                .fill(Color.cyan)
                                .frame(width: geo.size.width * CGFloat(progress), height: 2.5)
                        }
                    }
                    .frame(height: 2.5)
                    
                    HStack {
                        Text(formatTime(media.currentPlaybackPosition))
                        Spacer()
                        Text(formatTime(track.duration))
                    }
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.40))
                }
            }
        } else {
            // Standby Media Header (Minimalis, Native, Tanpa Gradasi Ungu-Biru & Tanpa Tulisan Promosi)
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.60))
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
                
                Button {
                    media.togglePlayPause()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.80))
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Resume Playback")
            }
            .frame(height: 52)
        }
    }
    
    // MARK: - Dedicated Lyrics Card (Di Bawah Media Controls)
    
    @ViewBuilder
    private var dedicatedLyricsCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 7.5))
                    .foregroundColor(.cyan.opacity(0.85))
                
                Text("LYRICS")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan.opacity(0.85))
                
                Spacer()
            }
            
            if !media.activeLyrics.isEmpty {
                // Tampilan 3 Baris Lirik Real-Time Sinkron (Karaoke Style)
                VStack(alignment: .leading, spacing: 2) {
                    if let prev = media.previousLyric, !prev.isEmpty {
                        Text(prev)
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(.white.opacity(0.35))
                            .lineLimit(1)
                    } else {
                        Text("...")
                            .font(.system(size: 8.5))
                            .foregroundColor(.white.opacity(0.15))
                            .lineLimit(1)
                    }
                    
                    if let current = media.currentLyric, !current.isEmpty {
                        HStack(spacing: 3) {
                            Text("♪")
                                .font(.system(size: 9, weight: .bold))
                            Text(current)
                                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.cyan)
                        .lineLimit(1)
                    } else {
                        Text("♪ (Instrumental)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.cyan.opacity(0.70))
                            .lineLimit(1)
                    }
                    
                    if let next = media.nextLyric, !next.isEmpty {
                        Text(next)
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(.white.opacity(0.40))
                            .lineLimit(1)
                    } else {
                        Color.clear.frame(height: 12)
                    }
                }
            } else if hasActiveMedia {
                VStack(alignment: .leading, spacing: 2) {
                    Text("No synchronized lyrics available")
                        .font(.system(size: 9.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.40))
                    Text("Lyrics will load automatically if track is found on LRCLIB")
                        .font(.system(size: 8.5, weight: .regular))
                        .foregroundColor(.white.opacity(0.25))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lyrics will sync here automatically")
                        .font(.system(size: 9.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.40))
                    Text("Start playing any song to see live synchronized lyrics")
                        .font(.system(size: 8.5, weight: .regular))
                        .foregroundColor(.white.opacity(0.25))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .frame(height: 75)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Compact Hover Content (Saat Hover 500x56)
    
    @ViewBuilder
    private var compactHoverContent: some View {
        HStack(spacing: 12) {
            if hasActiveMedia, let track = media.currentTrack {
                // SISI KIRI: Compact Media (Lebar ~300pt)
                HStack(spacing: 9) {
                    ZStack(alignment: .bottomTrailing) {
                        if let art = track.artwork {
                            Image(nsImage: art)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 38, height: 38)
                                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Image(systemName: track.mediaType == .video ? "play.rectangle.fill" : "music.note")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.80))
                                )
                        }
                        
                        if track.mediaType == .video {
                            Image(systemName: "video.fill")
                                .font(.system(size: 7))
                                .foregroundColor(.white)
                                .padding(2)
                                .background(Color.black.opacity(0.80))
                                .clipShape(Circle())
                                .offset(x: 2, y: 2)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if let lyric = media.currentLyric, !lyric.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "music.note")
                                    .font(.system(size: 8))
                                Text(lyric)
                                    .lineLimit(1)
                            }
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(.cyan)
                        } else {
                            Text(track.artist.isEmpty ? track.sourceApp : track.artist)
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundColor(.white.opacity(0.65))
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 5) {
                        Button {
                            media.previousTrack()
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 22, height: 22)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            media.togglePlayPause()
                        } label: {
                            Image(systemName: track.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.white.opacity(0.22))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            media.nextTrack()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 22, height: 22)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                // Standby Compact
                HStack(spacing: 9) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 32, height: 32)
                        Image(systemName: "music.note")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.60))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No Media Playing")
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.92))
                            .lineLimit(1)
                        Text("Click notch to open dashboard")
                            .font(.system(size: 8.5, weight: .regular))
                            .foregroundColor(.white.opacity(0.40))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button {
                        media.togglePlayPause()
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 24, height: 24)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
            }
            
            // DIVIDER
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1, height: 36)
            
            // SISI KANAN: Compact 7-Day Calendar (Lebar ~170pt)
            NotchCalendarView(isLarge: false)
                .frame(width: 170)
        }
        .padding(.horizontal, 14)
        .padding(.top, 9)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        guard !seconds.isNaN && !seconds.isInfinite && seconds > 0 else { return "00:00" }
        let totalSecs = Int(seconds)
        let mins = totalSecs / 60
        let secs = totalSecs % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
