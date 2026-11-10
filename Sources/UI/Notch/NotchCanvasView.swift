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
    
    private var isPodExpanded: Bool {
        return (store.preferences.expandOnHover && isHovered) || isExpanded
    }
    
    private var currentWidth: CGFloat {
        let base = CGFloat(store.preferences.width)
        if isPodExpanded {
            return hasActiveMedia ? max(base, 440.0) : max(base, 360.0)
        }
        return hasActiveMedia ? max(base, 220.0) : base
    }
    
    private var currentHeight: CGFloat {
        let base = CGFloat(store.preferences.height)
        if isPodExpanded {
            return hasActiveMedia ? 66.0 : 54.0
        }
        return base
    }
    
    private var activeCornerRadius: CGFloat {
        let base = CGFloat(store.preferences.cornerRadius)
        if isPodExpanded {
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
                .shadow(color: Color.black.opacity(isPodExpanded ? 0.45 : 0.0), radius: 14, x: 0, y: 6)
                
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
                if !isPodExpanded && hasActiveMedia, let track = media.currentTrack {
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
                
                // 4. Expanded State: Full Media Pod or Standby Quick Pod
                if isPodExpanded {
                    if hasActiveMedia, let track = media.currentTrack {
                        expandedMediaPod(track: track)
                    } else {
                        defaultExpandedContent
                    }
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
                withAnimation(.spring(response: 0.30, dampingFraction: 0.76)) {
                    isHovered = hovering
                }
            }
            .onTapGesture(count: 2) {
                SettingsWindowController.shared.show()
            }
            .onTapGesture(count: 1) {
                if store.preferences.expandOnClick {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.76)) {
                        isExpanded.toggle()
                    }
                }
            }
            .contextMenu {
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
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func expandedMediaPod(track: MediaTrack) -> some View {
        HStack(spacing: 12) {
            // Sisi Kiri: Artwork / Video Thumbnail
            ZStack(alignment: .bottomTrailing) {
                if let art = track.artwork {
                    Image(nsImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: track.mediaType == .video
                                    ? [Color.red.opacity(0.7), Color.orange.opacity(0.6)]
                                    : [Color.purple.opacity(0.7), Color.blue.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: track.mediaType == .video ? "play.rectangle.fill" : "music.note")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        )
                }
                
                if track.mediaType == .video {
                    Image(systemName: "video.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.white)
                        .padding(3)
                        .background(Color.black.opacity(0.75))
                        .clipShape(Circle())
                        .offset(x: 2, y: 2)
                }
            }
            .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)
            
            // Tengah: Track Title, Artist, & Live Synced Lyric
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(track.artist.isEmpty ? track.sourceApp : track.artist)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(1)
                
                // Baris lirik real-time jika ada lirik yang cocok
                if let lyric = media.currentLyric, !lyric.isEmpty {
                    Text("♪ \(lyric)")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.cyan)
                        .lineLimit(1)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Text(track.sourceApp)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(.white.opacity(0.40))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Sisi Kanan: Kontrol Playback (Prev, Play/Pause, Next)
            HStack(spacing: 8) {
                Button {
                    media.previousTrack()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Previous Track")
                
                Button {
                    media.togglePlayPause()
                } label: {
                    Image(systemName: track.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.22))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(track.isPlaying ? "Pause" : "Play")
                
                Button {
                    media.nextTrack()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Next Track")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
    
    @ViewBuilder
    private var defaultExpandedContent: some View {
        HStack(spacing: 12) {
            // Left: Sleek frosted icon
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 34, height: 34)
                
                Image(systemName: "music.note")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
            
            // Center: Standby description
            VStack(alignment: .leading, spacing: 2) {
                Text("No Media Playing")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(1)
                
                Text("Ready for Music, YouTube & Video")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(.white.opacity(0.50))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right: Play/Resume & Settings buttons
            HStack(spacing: 8) {
                Button {
                    media.togglePlayPause()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Play / Resume Media")
                
                Button {
                    SettingsWindowController.shared.show()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.70))
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Open YAN Settings")
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 9)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}
