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
    
    // Dimensi adaptif yang pas: Resting (200x30) -> Hover (500x56) -> Clicked (580x148)
    private var currentWidth: CGFloat {
        let base = CGFloat(store.preferences.width)
        if isExpanded {
            return 580.0
        }
        if isHovered && store.preferences.expandOnHover {
            return 500.0
        }
        return hasActiveMedia ? max(base, 220.0) : base
    }
    
    private var currentHeight: CGFloat {
        let base = CGFloat(store.preferences.height)
        if isExpanded {
            return 148.0
        }
        if isHovered && store.preferences.expandOnHover {
            return 56.0
        }
        return base
    }
    
    private var activeCornerRadius: CGFloat {
        let base = CGFloat(store.preferences.cornerRadius)
        if isExpanded {
            return 22.0
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
                    color: Color.black.opacity(isExpanded ? 0.60 : (isHovered ? 0.40 : 0.0)),
                    radius: isExpanded ? 18 : 12,
                    x: 0,
                    y: isExpanded ? 8 : 5
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
                
                // 4. Large Clicked State (580x148)
                if isExpanded {
                    largeUnifiedContent
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                } else if isHovered && store.preferences.expandOnHover {
                    // 5. Compact Hover State (500x56)
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
    
    // MARK: - Large Unified Content (580x148 pt: Musik + Lirik Menyatu Bersih)
    
    @ViewBuilder
    private var largeUnifiedContent: some View {
        HStack(spacing: 14) {
            // SISI KIRI: Unified Media Player + Seamless Flowing Lyrics (Lebar ~295pt)
            unifiedMediaPlayerAndLyrics
                .frame(width: 295)
            
            // DIVIDER TENGAH
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1, height: 110)
            
            // SISI KANAN: 1-Row Week Calendar + Schedule + Month Switcher (Lebar ~245pt)
            ZStack(alignment: .topTrailing) {
                NotchCalendarView(isLarge: true)
                    .frame(width: 240)
                
                // Tombol collapse kecil di pojok kanan atas
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        isExpanded = false
                    }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(.white.opacity(0.50))
                        .frame(width: 17, height: 17)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .offset(x: 3, y: -4)
                .help("Collapse Notch")
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
    }
    
    // MARK: - Unified Media Player & Lyrics View (Satu Desain Utuh & Modern)
    
    @ViewBuilder
    private var unifiedMediaPlayerAndLyrics: some View {
        if hasActiveMedia, let track = media.currentTrack {
            VStack(alignment: .leading, spacing: 6) {
                // Baris 1: Artwork + Track Info + Kontrol Playback (Prev, Play, Next)
                HStack(spacing: 9) {
                    ZStack(alignment: .bottomTrailing) {
                        if let art = track.artwork {
                            Image(nsImage: art)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 38, height: 38)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Image(systemName: track.mediaType == .video ? "play.rectangle.fill" : "music.note")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.80))
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
                    .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 1.5) {
                        Text(track.title)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(track.artist.isEmpty ? track.sourceApp : track.artist)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.60))
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 0)
                    
                    // Kontrol Playback Langsung di Baris Atas
                    HStack(spacing: 5) {
                        Button {
                            media.previousTrack()
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 10.5))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 22, height: 22)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            media.togglePlayPause()
                        } label: {
                            Image(systemName: track.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 11.5))
                                .foregroundColor(.black)
                                .frame(width: 24, height: 24)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            media.nextTrack()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 10.5))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: 22, height: 22)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Baris 2: Scrubber Garis Waktu Real-Time Halus
                VStack(spacing: 2) {
                    GeometryReader { geo in
                        let progress = track.duration > 0 ? min(1.0, max(0.0, media.currentPlaybackPosition / track.duration)) : 0.0
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.14))
                                .frame(height: 2)
                            Capsule()
                                .fill(Color.cyan)
                                .frame(width: geo.size.width * CGFloat(progress), height: 2)
                        }
                    }
                    .frame(height: 2)
                    
                    HStack {
                        Text(formatTime(media.currentPlaybackPosition))
                        Spacer()
                        Text(formatTime(track.duration))
                    }
                    .font(.system(size: 7.5, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))
                }
                
                // Baris 3: Lirik Real-Time yang Mengalir Alami (Menyatu Tanpa Kotak Terpisah)
                VStack(alignment: .leading, spacing: 2.5) {
                    if !media.activeLyrics.isEmpty {
                        if let prev = media.previousLyric, !prev.isEmpty {
                            Text(prev)
                                .font(.system(size: 8.5, weight: .regular))
                                .foregroundColor(.white.opacity(0.30))
                                .lineLimit(1)
                        }
                        
                        if let current = media.currentLyric, !current.isEmpty {
                            HStack(spacing: 4) {
                                Text("♪")
                                    .font(.system(size: 8.5, weight: .bold))
                                Text(current)
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.cyan)
                            .lineLimit(1)
                        } else {
                            Text("♪ (Instrumental)")
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundColor(.cyan.opacity(0.70))
                                .lineLimit(1)
                        }
                        
                        if let next = media.nextLyric, !next.isEmpty {
                            Text(next)
                                .font(.system(size: 8.5, weight: .regular))
                                .foregroundColor(.white.opacity(0.35))
                                .lineLimit(1)
                        }
                    } else {
                        Text("No synchronized lyrics found")
                            .font(.system(size: 9, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.35))
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            // Standby Minimalis Bersih & Menyatu
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 9) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 38, height: 38)
                        
                        Image(systemName: "music.note")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.50))
                    }
                    
                    VStack(alignment: .leading, spacing: 1.5) {
                        Text("No Media Playing")
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
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
                            .font(.system(size: 10.5))
                            .foregroundColor(.white.opacity(0.80))
                            .frame(width: 24, height: 24)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Resume Playback")
                }
                
                Text("Lyrics and timeline will synchronize here automatically during playback.")
                    .font(.system(size: 8.5, weight: .regular))
                    .foregroundColor(.white.opacity(0.25))
                    .padding(.top, 4)
            }
        }
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
