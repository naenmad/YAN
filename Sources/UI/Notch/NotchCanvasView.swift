import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Interactive Media Scrubber (Drag & Drop / Click to Seek)

struct MediaScrubberView: View {
    let duration: TimeInterval
    let currentTime: TimeInterval
    let onSeek: (TimeInterval) -> Void
    
    @State private var isDragging: Bool = false
    @State private var dragPosition: TimeInterval = 0
    @State private var isHovered: Bool = false
    
    private var displayTime: TimeInterval {
        isDragging ? dragPosition : currentTime
    }
    
    private var progress: Double {
        guard duration > 0, !duration.isNaN, !duration.isInfinite else { return 0.0 }
        return min(1.0, max(0.0, displayTime / duration))
    }
    
    var body: some View {
        VStack(spacing: 3) {
            GeometryReader { geo in
                let totalWidth = geo.size.width
                let thumbSize: CGFloat = (isHovered || isDragging) ? 10 : 7
                let trackHeight: CGFloat = (isHovered || isDragging) ? 4 : 2.5
                
                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(height: trackHeight)
                    
                    // Elapsed fill
                    Capsule()
                        .fill(Color.cyan)
                        .frame(width: max(0, totalWidth * CGFloat(progress)), height: trackHeight)
                    
                    // Draggable Scrubber Thumb (Circle knob)
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: Color.black.opacity(0.45), radius: 2, x: 0, y: 1)
                        .offset(x: max(0, min(totalWidth - thumbSize, (totalWidth * CGFloat(progress)) - (thumbSize / 2))))
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let ratio = max(0.0, min(1.0, Double(value.location.x / totalWidth)))
                            dragPosition = ratio * duration
                        }
                        .onEnded { value in
                            let ratio = max(0.0, min(1.0, Double(value.location.x / totalWidth)))
                            let targetTime = ratio * duration
                            onSeek(targetTime)
                            isDragging = false
                        }
                )
            }
            .frame(height: 14)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
            
            HStack {
                Text(formatTime(displayTime))
                Spacer()
                Text(formatTime(duration))
            }
            .font(.system(size: 8, weight: .medium, design: .monospaced))
            .foregroundColor(.white.opacity(0.40))
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        guard !seconds.isNaN && !seconds.isInfinite && seconds > 0 else { return "00:00" }
        let total = Int(seconds)
        if total >= 3600 {
            let hours = total / 3600
            let mins = (total % 3600) / 60
            let secs = total % 60
            return String(format: "%d:%02d:%02d", hours, mins, secs)
        } else {
            let mins = total / 60
            let secs = total % 60
            return String(format: "%02d:%02d", mins, secs)
        }
    }
}

// MARK: - NotchCanvasView

public enum NotchPage: Int, CaseIterable {
    case dashboard = 0 // Media Player + Calendar & Schedule
    case dropZone = 1  // AirDrop Target + Temporary Stash Shelf
}

public struct NotchCanvasView: View {
    @ObservedObject var store: NotchSettingsStore = .shared
    @ObservedObject var media: MediaManager = .shared
    @ObservedObject var shelf: ShelfManager = .shared
    
    @State private var isHovered: Bool = false
    @State private var isExpanded: Bool = false
    @State private var activePage: NotchPage = .dashboard
    
    // Automatic collapse monitoring & file drag targeting
    @State private var outsideClickMonitor: Any? = nil
    @State private var outsideLocalMonitor: Any? = nil
    @State private var isGlobalDragTargeted: Bool = false
    
    private var hasActiveMedia: Bool {
        return media.currentTrack != nil && media.currentTrack!.isValid
    }
    
    // Dimensi adaptif yang dapat disetel: Resting -> Hover -> Clicked
    private var currentWidth: CGFloat {
        let base = CGFloat(store.preferences.width)
        if isExpanded {
            return CGFloat(store.preferences.clickedWidth)
        }
        if isHovered && store.preferences.expandOnHover {
            return CGFloat(store.preferences.hoverWidth)
        }
        if hasActiveMedia && store.preferences.normalStateMediaDisplay != .empty {
            return store.preferences.normalStateMediaDisplay == .lyrics ? max(base, 250.0) : max(base, 220.0)
        }
        return base
    }
    
    private var currentHeight: CGFloat {
        let base = CGFloat(store.preferences.height)
        if isExpanded {
            return CGFloat(store.preferences.clickedHeight)
        }
        if isHovered && store.preferences.expandOnHover {
            if store.preferences.lockHeightOnHover {
                return base
            }
            return CGFloat(store.preferences.hoverHeight)
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
                    if store.preferences.normalStateMediaDisplay != .empty {
                        HStack(spacing: 8) {
                            if let art = track.artwork {
                                Image(nsImage: art)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 16, height: 16)
                                    .clipShape(RoundedRectangle(cornerRadius: 3.5, style: .continuous))
                            } else {
                                Image(systemName: track.mediaType == .video ? "play.rectangle.fill" : "music.note")
                                    .font(.system(size: 9.5))
                                    .foregroundColor(.cyan)
                            }
                            
                            if store.preferences.normalStateMediaDisplay == .lyrics {
                                if let lyric = media.currentLyric, !lyric.isEmpty {
                                    HStack(spacing: 3) {
                                        Text("♪")
                                            .font(.system(size: 8, weight: .bold))
                                        Text(lyric)
                                            .lineLimit(1)
                                    }
                                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                                    .foregroundColor(.cyan)
                                    .frame(maxWidth: 175, alignment: .leading)
                                } else {
                                    Text(track.title)
                                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.85))
                                        .lineLimit(1)
                                        .frame(maxWidth: 175, alignment: .leading)
                                }
                            } else {
                                Text(track.title)
                                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(1)
                                    .frame(maxWidth: 145, alignment: .leading)
                            }
                            
                            Spacer()
                            
                            Circle()
                                .fill(track.isPlaying ? Color.green : Color.orange)
                                .frame(width: 4, height: 4)
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 7)
                        .transition(.opacity)
                    }
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
        .onChange(of: isExpanded) { expanded in
            if expanded {
                startOutsideClickMonitoring()
            } else {
                stopOutsideClickMonitoring()
            }
        }
        .onDisappear {
            stopOutsideClickMonitoring()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            if isExpanded {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    isExpanded = false
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isGlobalDragTargeted) { providers in
            shelf.extractURLs(from: providers) { urls in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    shelf.addItems(urls: urls)
                }
            }
            return true
        }
        .onChange(of: isGlobalDragTargeted) { targeted in
            if targeted {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    isExpanded = true
                    activePage = .dropZone
                }
            }
        }
    }
    
    // MARK: - Outside Click Handling
    
    private func startOutsideClickMonitoring() {
        stopOutsideClickMonitoring()
        
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            handleOutsideClick(event: event)
        }
        
        outsideLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            handleOutsideClick(event: event)
            return event
        }
    }
    
    private func stopOutsideClickMonitoring() {
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
        }
        if let monitor = outsideLocalMonitor {
            NSEvent.removeMonitor(monitor)
            outsideLocalMonitor = nil
        }
    }
    
    private func handleOutsideClick(event: NSEvent) {
        guard isExpanded else { return }
        
        let clickPoint = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(clickPoint) } ?? NSScreen.main ?? NSScreen.screens.first
        guard let targetScreen = screen else {
            collapseNotch()
            return
        }
        
        let screenFrame = targetScreen.frame
        let currentW = CGFloat(store.preferences.clickedWidth)
        let currentH = CGFloat(store.preferences.clickedHeight)
        
        // Notch area at the top center of the screen (with 12pt safety buffer)
        let notchRect = NSRect(
            x: screenFrame.midX - (currentW / 2) - 12,
            y: screenFrame.maxY - currentH - 12,
            width: currentW + 24,
            height: currentH + 24
        )
        
        if !notchRect.contains(clickPoint) {
            DispatchQueue.main.async {
                self.collapseNotch()
            }
        }
    }
    
    private func collapseNotch() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
            isExpanded = false
        }
    }
    
    // MARK: - Large Unified Content (Mode Clicked / Expanded)
    
    @ViewBuilder
    private var largeUnifiedContent: some View {
        let currentW = CGFloat(store.preferences.clickedWidth)
        let currentH = CGFloat(store.preferences.clickedHeight)
        let availableW = max(360.0, currentW - 53) // padding 28 + spacing 24 + divider 1
        let leftWidth = max(230.0, availableW * 0.54)
        let rightWidth = max(190.0, availableW - leftWidth)
        let dividerHeight = max(55.0, currentH - 58)
        
        VStack(spacing: 6) {
            // Header Bar: Page Switcher Capsule + Collapse Chevron
            HStack(spacing: 8) {
                // Page Switcher Capsule
                HStack(spacing: 2) {
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            activePage = .dashboard
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.grid.2x2.fill")
                                .font(.system(size: 8))
                            Text("Dashboard")
                                .font(.system(size: 8.5, weight: .semibold))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(activePage == .dashboard ? Color.white.opacity(0.18) : Color.clear)
                        .foregroundColor(activePage == .dashboard ? .white : .white.opacity(0.45))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            activePage = .dropZone
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "tray.and.arrow.down.fill")
                                .font(.system(size: 8))
                            Text("Drop Zone")
                                .font(.system(size: 8.5, weight: .semibold))
                            if !shelf.items.isEmpty {
                                Text("\(shelf.items.count)")
                                    .font(.system(size: 7.5, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 4.5)
                                    .padding(.vertical, 0.5)
                                    .background(Color.cyan)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(activePage == .dropZone ? Color.cyan.opacity(0.25) : Color.clear)
                        .foregroundColor(activePage == .dropZone ? .cyan : .white.opacity(0.45))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(2)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
                
                Spacer()
                
                // Collapse button
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        isExpanded = false
                    }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(.white.opacity(0.50))
                        .frame(width: 18, height: 18)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Collapse Notch")
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)
            
            // Page Body Content
            if activePage == .dashboard {
                HStack(spacing: 12) {
                    unifiedMediaPlayerSection
                        .frame(width: leftWidth)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 1, height: dividerHeight)
                    
                    NotchCalendarView(isLarge: true)
                        .frame(width: rightWidth)
                }
                .padding(.horizontal, 14)
                .transition(.opacity)
            } else {
                NotchDropZoneView()
                    .transition(.opacity)
            }
        }
    }
    
    // MARK: - Unified Media Player Section
    
    @ViewBuilder
    private var unifiedMediaPlayerSection: some View {
        if hasActiveMedia, let track = media.currentTrack {
            VStack(alignment: .leading, spacing: 6) {
                // BARIS 1: Artwork + Title + Artist + Source App
                HStack(spacing: 9) {
                    ZStack(alignment: .bottomTrailing) {
                        if let art = track.artwork {
                            Image(nsImage: art)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 38, height: 38)
                                .clipShape(RoundedRectangle(cornerRadius: 7.5, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 7.5, style: .continuous)
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
                        Text(track.title)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        HStack(spacing: 5) {
                            Text(track.artist.isEmpty ? track.sourceApp : track.artist)
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundColor(.white.opacity(0.60))
                                .lineLimit(1)
                            
                            Text(track.sourceApp)
                                .font(.system(size: 7.5, weight: .semibold))
                                .foregroundColor(.white.opacity(0.35))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 0.5)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                
                // BARIS 2: Interactive Scrubber Slider (Bisa di-Drag & Drop / Diklik untuk Geser Waktu)
                MediaScrubberView(
                    duration: track.duration,
                    currentTime: media.currentPlaybackPosition,
                    onSeek: { targetTime in
                        media.seek(to: targetTime)
                    }
                )
                
                // BARIS 3: Kontrol Playback Terpusat & Nyaman Diklik (Prev, Play/Pause, Next)
                HStack(spacing: 22) {
                    Spacer()
                    
                    Button {
                        media.previousTrack()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 26, height: 26)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Previous Track")
                    
                    Button {
                        media.togglePlayPause()
                    } label: {
                        Image(systemName: track.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 28, height: 28)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .help(track.isPlaying ? "Pause" : "Play")
                    
                    Button {
                        media.nextTrack()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 26, height: 26)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Next Track")
                    
                    Spacer()
                }
                
                // BARIS 4: Tampilan 3 Baris Lirik Real-Time (Atau Kartu Video Interaktif)
                if track.mediaType == .video {
                    // Video Playback Card (-15s dan +15s jump buttons)
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 1.5) {
                            HStack(spacing: 4) {
                                Image(systemName: "play.rectangle.fill")
                                    .font(.system(size: 8.5))
                                    .foregroundColor(.red.opacity(0.85))
                                Text("Video Stream")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            Text(track.sourceApp)
                                .font(.system(size: 7.5, weight: .medium))
                                .foregroundColor(.white.opacity(0.40))
                                .lineLimit(1)
                        }
                        
                        Spacer(minLength: 4)
                        
                        HStack(spacing: 6) {
                            Button {
                                media.seek(to: max(0, media.currentPlaybackPosition - 15))
                            } label: {
                                HStack(spacing: 2) {
                                    Image(systemName: "gobackward.15")
                                        .font(.system(size: 9.5, weight: .semibold))
                                    Text("15s")
                                        .font(.system(size: 8, weight: .medium))
                                }
                                .foregroundColor(.white.opacity(0.80))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .help("Rewind 15 seconds")
                            
                            Button {
                                media.seek(to: min(track.duration, media.currentPlaybackPosition + 15))
                            } label: {
                                HStack(spacing: 2) {
                                    Text("15s")
                                        .font(.system(size: 8, weight: .medium))
                                    Image(systemName: "goforward.15")
                                        .font(.system(size: 9.5, weight: .semibold))
                                }
                                .foregroundColor(.white.opacity(0.80))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .help("Skip forward 15 seconds")
                        }
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                } else if !media.activeLyrics.isEmpty {
                    // TAMPILAN 3 BARIS LIRIK REAL-TIME (Sesuai Permintaan User: 3 Baris Karaoke)
                    VStack(alignment: .leading, spacing: 1.5) {
                        // 1. Lirik Sebelumnya (Faded)
                        Text(media.previousLyric ?? " ")
                            .font(.system(size: 8.5, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.35))
                            .lineLimit(1)
                        
                        // 2. Lirik Aktif (Highlight Cyan)
                        HStack(spacing: 3) {
                            Text("♪")
                                .font(.system(size: 8.5, weight: .bold))
                            Text(media.currentLyric ?? "Instrumental")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .lineLimit(1)
                        }
                        .foregroundColor(.cyan)
                        
                        // 3. Lirik Berikutnya (Faded)
                        Text(media.nextLyric ?? " ")
                            .font(.system(size: 8.5, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.35))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3.5)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                } else {
                    // Audio Playback Card (Jika musik tidak memiliki lirik di database)
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 1.5) {
                            HStack(spacing: 4) {
                                Image(systemName: "music.note")
                                    .font(.system(size: 8.5))
                                    .foregroundColor(.cyan.opacity(0.85))
                                Text(track.album.isEmpty ? "Audio Playback" : track.album)
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(1)
                            }
                            Text(track.sourceApp)
                                .font(.system(size: 7.5, weight: .medium))
                                .foregroundColor(.white.opacity(0.40))
                                .lineLimit(1)
                        }
                        
                        Spacer(minLength: 4)
                        
                        HStack(spacing: 6) {
                            Button {
                                media.seek(to: max(0, media.currentPlaybackPosition - 15))
                            } label: {
                                HStack(spacing: 2) {
                                    Image(systemName: "gobackward.15")
                                        .font(.system(size: 9.5, weight: .semibold))
                                    Text("15s")
                                        .font(.system(size: 8, weight: .medium))
                                }
                                .foregroundColor(.white.opacity(0.80))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .help("Rewind 15 seconds")
                            
                            Button {
                                media.seek(to: min(track.duration, media.currentPlaybackPosition + 15))
                            } label: {
                                HStack(spacing: 2) {
                                    Text("15s")
                                        .font(.system(size: 8, weight: .medium))
                                    Image(systemName: "goforward.15")
                                        .font(.system(size: 9.5, weight: .semibold))
                                }
                                .foregroundColor(.white.opacity(0.80))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .help("Skip forward 15 seconds")
                        }
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
            }
        } else {
            // Standby Minimalis Bersih
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
                }
                
                HStack(spacing: 16) {
                    Spacer()
                    Button {
                        media.togglePlayPause()
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11.5))
                            .foregroundColor(.black)
                            .frame(width: 28, height: 28)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Resume Playback")
                    Spacer()
                }
                .padding(.top, 6)
                
                Text("Controls and timeline will activate automatically during playback.")
                    .font(.system(size: 8.5, weight: .regular))
                    .foregroundColor(.white.opacity(0.25))
                    .padding(.top, 2)
            }
        }
    }
    
    // MARK: - Compact Hover Content (Mode Hover)
    
    @ViewBuilder
    private var compactHoverContent: some View {
        let hoverH = CGFloat(store.preferences.hoverHeight)
        let topPad = max(4.0, (hoverH - 40.0) / 2.0)
        
        HStack(spacing: 8) {
            if activePage == .dashboard {
                compactDashboardGlance
                    .transition(.opacity)
            } else {
                NotchCompactDropZoneView()
                    .transition(.opacity)
            }
            
            // Hover Page Switcher Button
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    activePage = (activePage == .dashboard ? .dropZone : .dashboard)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(activePage == .dropZone ? Color.cyan.opacity(0.20) : Color.white.opacity(0.08))
                        .frame(width: 22, height: 22)
                    
                    Image(systemName: activePage == .dashboard ? "tray.and.arrow.down" : "square.grid.2x2")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(activePage == .dropZone ? .cyan : .white.opacity(0.70))
                }
            }
            .buttonStyle(.plain)
            .help(activePage == .dashboard ? "Switch to Drop Zone" : "Switch to Dashboard")
            .padding(.trailing, 6)
        }
        .padding(.leading, 10)
        .padding(.top, topPad)
    }
    
    // MARK: - Compact Dashboard Glance (Hover Page 1)
    
    @ViewBuilder
    private var compactDashboardGlance: some View {
        let hoverH = CGFloat(store.preferences.hoverHeight)
        let dividerH = max(20.0, hoverH - 22.0)
        
        HStack(spacing: 10) {
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
                        
                        if track.mediaType == .video {
                            Text(track.artist.isEmpty ? track.sourceApp : track.artist)
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundColor(.white.opacity(0.65))
                                .lineLimit(1)
                        } else if let lyric = media.currentLyric, !lyric.isEmpty {
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
                .frame(width: 1, height: dividerH)
            
            // SISI KANAN: Compact 7-Day Calendar (Lebar ~170pt)
            NotchCalendarView(isLarge: false)
                .frame(width: 170)
        }
    }
}
