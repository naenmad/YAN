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

public enum DashboardRightTab: String, CaseIterable, Identifiable {
    case lyrics = "Lyrics"
    case calendar = "Calendar"
    public var id: String { rawValue }
}

// MARK: - NotchCanvasView

public struct NotchCanvasView: View {
    @ObservedObject var store: NotchSettingsStore = .shared
    @ObservedObject var media: MediaManager = .shared
    @ObservedObject var shelf: ShelfManager = .shared
    @ObservedObject var pageManager: NotchPageManager = .shared
    
    @State private var isHovered: Bool = false
    @State private var isExpanded: Bool = false
    @State private var dashboardTab: DashboardRightTab = .lyrics
    
    private var activePage: NotchPage {
        pageManager.activePage
    }
    
    // Automatic collapse monitoring, trackpad 2-finger swipe & file drag targeting
    @State private var outsideClickMonitor: Any? = nil
    @State private var outsideLocalMonitor: Any? = nil
    @State private var trackpadSwipeMonitor: Any? = nil
    @State private var trackpadSwipeGlobalMonitor: Any? = nil
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
                // 1. Notch Body Background (Liquid Glass / Clear Glass / Classic Black)
                notchBackgroundLayer
                
                // 2. Notch Specular Rim & Border
                notchBorderLayer
                
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
                                    HStack(spacing: 4) {
                                        Image(systemName: "music.note")
                                            .font(.system(size: 8))
                                            .foregroundColor(.cyan)
                                        MarqueeText(
                                            lyric,
                                            fontSize: 9.5,
                                            fontWeight: .semibold,
                                            color: .cyan
                                        )
                                    }
                                    .frame(maxWidth: 175, alignment: .leading)
                                } else {
                                    MarqueeText(
                                        track.title,
                                        fontSize: 9.5,
                                        fontWeight: .semibold,
                                        color: .white.opacity(0.85)
                                    )
                                    .frame(maxWidth: 175, alignment: .leading)
                                }
                            } else {
                                MarqueeText(
                                    track.title,
                                    fontSize: 9.5,
                                    fontWeight: .semibold,
                                    color: .white.opacity(0.85)
                                )
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
            .simultaneousGesture(
                DragGesture(minimumDistance: 25)
                    .onEnded { value in
                        let dx = value.translation.width
                        let dy = abs(value.translation.height)
                        if abs(dx) > dy * 1.2 {
                            if dx < -25 {
                                pageManager.nextPage()
                            } else if dx > 25 {
                                pageManager.previousPage()
                            }
                        }
                    }
            )
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
        .onAppear {
            startTrackpadSwipeMonitoring()
        }
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
            updateCameraLifecycle()
        }
        .onChange(of: pageManager.activePageIndex) { _ in
            updateCameraLifecycle()
        }
        .onChange(of: isHovered) { _ in
            updateCameraLifecycle()
        }
        .onDisappear {
            stopOutsideClickMonitoring()
            stopTrackpadSwipeMonitoring()
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
                    pageManager.switchToPage(.dropZone)
                }
            }
        }
    }
    
    // MARK: - Trackpad 2-Finger Swipe Handling
    
    private func startTrackpadSwipeMonitoring() {
        stopTrackpadSwipeMonitoring()
        trackpadSwipeMonitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel, .swipe]) { event in
            // Intersep swipe horizontal trackpad hanya saat kursor mouse berada di area notch (hovering atau expanded)
            guard self.isHovered || self.isExpanded else { return event }
            
            if event.type == .scrollWheel {
                if self.pageManager.handleScrollWheel(event: event) {
                    return nil
                }
            } else if event.type == .swipe {
                if self.pageManager.handleSwipe(event: event) {
                    return nil
                }
            }
            return event
        }
        
        trackpadSwipeGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.scrollWheel, .swipe]) { event in
            guard self.isHovered || self.isExpanded else { return }
            if event.type == .scrollWheel {
                _ = self.pageManager.handleScrollWheel(event: event)
            } else if event.type == .swipe {
                _ = self.pageManager.handleSwipe(event: event)
            }
        }
    }
    
    private func stopTrackpadSwipeMonitoring() {
        if let monitor = trackpadSwipeMonitor {
            NSEvent.removeMonitor(monitor)
            trackpadSwipeMonitor = nil
        }
        if let monitor = trackpadSwipeGlobalMonitor {
            NSEvent.removeMonitor(monitor)
            trackpadSwipeGlobalMonitor = nil
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
    
    private func updateCameraLifecycle() {
        let currentPage = pageManager.currentCustomPage
        let hasCamera = currentPage.primaryWidget == .camera || currentPage.secondaryWidget == .camera || currentPage.tertiaryWidget == .camera
        let shouldCameraRun = hasCamera && (isExpanded || isHovered)
        if shouldCameraRun {
            CameraManager.shared.startSession()
        } else {
            CameraManager.shared.stopSession()
        }
    }
    
    // MARK: - Notch Background Layer (Liquid Glass / Clear Glass / Classic Black)
    
    @ViewBuilder
    private var notchBackgroundLayer: some View {
        let shape = NotchShape(
            cornerRadius: activeCornerRadius,
            earRadius: CGFloat(store.preferences.earRadius)
        )
        
        switch store.preferences.themeMode {
        case .classicBlack:
            shape
                .fill(Color.black)
                .shadow(
                    color: Color.black.opacity(isExpanded ? 0.60 : (isHovered ? 0.40 : 0.0)),
                    radius: isExpanded ? 18 : 12,
                    x: 0,
                    y: isExpanded ? 8 : 5
                )
                
        case .liquidGlass:
            ZStack {
                // A. Native Apple Frosted Material
                shape
                    .fill(.ultraThinMaterial)
                
                // B. Translucent Deep Glass Tint
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.05, green: 0.06, blue: 0.08).opacity(store.preferences.glassOpacity),
                                Color(red: 0.02, green: 0.02, blue: 0.03).opacity(store.preferences.glassOpacity * 0.95)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // C. Liquid Specular Sheen (Refractive top gloss)
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.04),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
            .shadow(
                color: Color.black.opacity(isExpanded ? 0.55 : 0.38),
                radius: isExpanded ? 22 : 14,
                x: 0,
                y: isExpanded ? 9 : 5
            )
            
        case .clearGlass:
            ZStack {
                // A. Native Material Frost
                shape
                    .fill(.thinMaterial)
                
                // B. Minimal Dark Tint for Text Legibility
                shape
                    .fill(Color.black.opacity(store.preferences.glassOpacity * 0.42))
            }
            .shadow(
                color: Color.black.opacity(isExpanded ? 0.45 : 0.28),
                radius: isExpanded ? 16 : 10,
                x: 0,
                y: isExpanded ? 7 : 4
            )
        }
    }
    
    // MARK: - Notch Border & Specular Rim Layer
    
    @ViewBuilder
    private var notchBorderLayer: some View {
        let borderShape = NotchBorderShape(
            cornerRadius: activeCornerRadius,
            earRadius: CGFloat(store.preferences.earRadius)
        )
        
        switch store.preferences.themeMode {
        case .classicBlack:
            if store.preferences.showOutline {
                borderShape
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
            
        case .liquidGlass:
            // Liquid Glass Rim: Specular gradient with subtle refraction
            borderShape
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.48),
                            Color.white.opacity(0.18),
                            Color.cyan.opacity(0.28),
                            Color.white.opacity(0.38)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
                
        case .clearGlass:
            // High-precision crisp glass perimeter
            borderShape
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.55),
                            Color.white.opacity(0.20),
                            Color.white.opacity(0.45)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        }
    }
    
    // MARK: - Large Unified Content (Mode Clicked / Dynamic Page Layout)
    
    @ViewBuilder
    private var largeUnifiedContent: some View {
        let currentW = CGFloat(store.preferences.clickedWidth)
        let currentH = CGFloat(store.preferences.clickedHeight)
        let availableW = max(360.0, currentW - 57) // horizontal padding 28 + spacing 28 + divider 1
        let dividerHeight = max(70.0, currentH - 28)
        let page = pageManager.currentCustomPage
        
        Group {
            switch page.layout {
            case .dualPod:
                let podWidth = availableW / 2
                HStack(spacing: 14) {
                    NotchWidgetHostView(type: page.primaryWidget, size: .medium)
                        .frame(width: podWidth)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 1, height: dividerHeight)
                    
                    NotchWidgetHostView(type: page.secondaryWidget ?? .lyrics, size: .medium)
                        .frame(width: podWidth)
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .transition(.opacity)
                
            case .fullStage:
                NotchWidgetHostView(type: page.primaryWidget, size: .large)
                    .frame(width: availableW)
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
                    .transition(.opacity)
                
            case .triplePod:
                let podW3 = max(100.0, (availableW - 30) / 3)
                HStack(spacing: 10) {
                    NotchWidgetHostView(type: page.primaryWidget, size: .small)
                        .frame(width: podW3)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 1, height: dividerHeight)
                    
                    NotchWidgetHostView(type: page.secondaryWidget ?? .hardwareHUD, size: .small)
                        .frame(width: podW3)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 1, height: dividerHeight)
                    
                    NotchWidgetHostView(type: page.tertiaryWidget ?? .quickTools, size: .small)
                        .frame(width: podW3)
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .transition(.opacity)
            }
        }
    }
    
    // MARK: - Dashboard Media Left Pod (Player, Artwork, Scrubber & Controls)
    
    @ViewBuilder
    private var dashboardMediaLeftPod: some View {
        if hasActiveMedia, let track = media.currentTrack {
            VStack(alignment: .leading, spacing: 7) {
                // 1. Artwork + Title + Artist + Source Capsule
                HStack(spacing: 10) {
                    ZStack(alignment: .bottomTrailing) {
                        if let art = track.artwork {
                            Image(nsImage: art)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 46, height: 46)
                                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 46, height: 46)
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
                                .padding(2.5)
                                .background(Color.black.opacity(0.85))
                                .clipShape(Circle())
                                .offset(x: 2, y: 2)
                        }
                    }
                    .shadow(color: Color.black.opacity(0.35), radius: 3, x: 0, y: 1.5)
                    
                    VStack(alignment: .leading, spacing: 2.5) {
                        MarqueeText(
                            track.title,
                            fontSize: 12.5,
                            fontWeight: .bold,
                            color: .white
                        )
                        
                        Text(track.artist.isEmpty ? track.sourceApp : track.artist)
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.65))
                            .lineLimit(1)
                        
                        HStack(spacing: 5) {
                            Circle()
                                .fill(track.isPlaying ? Color.green : Color.orange)
                                .frame(width: 4.5, height: 4.5)
                            
                            Text(track.sourceApp)
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(.white.opacity(0.40))
                            
                            if !track.album.isEmpty {
                                Text("•")
                                    .font(.system(size: 7.5))
                                    .foregroundColor(.white.opacity(0.25))
                                Text(track.album)
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.white.opacity(0.35))
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                
                // 2. Interactive Scrubber Timeline
                MediaScrubberView(
                    duration: track.duration,
                    currentTime: media.currentPlaybackPosition,
                    onSeek: { targetTime in
                        media.seek(to: targetTime)
                    }
                )
                
                // 3. Playback Controls (Prev, Play/Pause, Next)
                HStack(spacing: 18) {
                    Spacer()
                    
                    if track.mediaType == .video {
                        Button {
                            media.seek(to: max(0, media.currentPlaybackPosition - 15))
                        } label: {
                            Image(systemName: "gobackward.15")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.75))
                                .frame(width: 24, height: 24)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("Rewind 15s")
                    }
                    
                    Button {
                        media.previousTrack()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 13, weight: .semibold))
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
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 32, height: 32)
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
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Next Track")
                    
                    if track.mediaType == .video {
                        Button {
                            media.seek(to: min(track.duration, media.currentPlaybackPosition + 15))
                        } label: {
                            Image(systemName: "goforward.15")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.75))
                                .frame(width: 24, height: 24)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("Forward 15s")
                    }
                    
                    Spacer()
                }
            }
        } else {
            // Standby Minimalis Bersih saat Tidak Ada Media
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
                    Button {
                        media.togglePlayPause()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("Resume")
                                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .help("Resume Playback")
                    Spacer()
                }
                
                Spacer(minLength: 0)
            }
        }
    }
    
    // MARK: - Dashboard Right Pod (Dedicated Lyrics Stage / Calendar Switcher)
    
    @ViewBuilder
    private var dashboardRightPod: some View {
        let effectiveTab = hasActiveMedia ? dashboardTab : .calendar
        
        VStack(alignment: .leading, spacing: 6) {
            if hasActiveMedia {
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: effectiveTab == .lyrics ? "quote.bubble.fill" : "calendar")
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundColor(.cyan)
                        Text(effectiveTab == .lyrics ? "LYRICS" : "CALENDAR")
                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                            .tracking(0.6)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                dashboardTab = .lyrics
                            }
                        } label: {
                            Text("Lyrics")
                                .font(.system(size: 8, weight: dashboardTab == .lyrics ? .bold : .medium, design: .rounded))
                                .foregroundColor(dashboardTab == .lyrics ? .white : .white.opacity(0.40))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(dashboardTab == .lyrics ? Color.white.opacity(0.18) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                dashboardTab = .calendar
                            }
                        } label: {
                            Text("Calendar")
                                .font(.system(size: 8, weight: dashboardTab == .calendar ? .bold : .medium, design: .rounded))
                                .foregroundColor(dashboardTab == .calendar ? .white : .white.opacity(0.40))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(dashboardTab == .calendar ? Color.white.opacity(0.18) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(2)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                }
            }
            
            if effectiveTab == .lyrics {
                lyricsStageView
            } else {
                NotchCalendarView(isLarge: true)
            }
        }
    }
    
    // MARK: - Synchronized Karaoke Lyrics Stage
    
    @ViewBuilder
    private var lyricsStageView: some View {
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
            
            VStack(alignment: .leading, spacing: 5) {
                Spacer(minLength: 0)
                
                // 1. Previous Line (faded)
                Text(prevLine ?? " ")
                    .font(.system(size: 9.5, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.28))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 2. Current Line (Highlighted in cyan pill, autoscrolls if long)
                HStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(.cyan)
                    
                    MarqueeText(
                        currentLine ?? "Instrumental",
                        fontSize: 12,
                        fontWeight: .bold,
                        color: .cyan
                    )
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.cyan.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .strokeBorder(Color.cyan.opacity(0.28), lineWidth: 0.8)
                        )
                )
                
                // 3. Next Line (semi-faded)
                Text(nextLine ?? " ")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.48))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 4. Upcoming Line (faded)
                if let upcoming = upcomingLine {
                    Text(upcoming)
                        .font(.system(size: 9, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.25))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Placeholder jika musik tidak memiliki file lirik sinkron (.lrc)
            VStack(spacing: 6) {
                Spacer(minLength: 0)
                
                Image(systemName: "music.quarternote.3")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.25))
                
                Text("No Synced Lyrics")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.60))
                
                Text("Synced lyrics unavailable for this track")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(.white.opacity(0.35))
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        dashboardTab = .calendar
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))
                        Text("Show Calendar")
                            .font(.system(size: 9.5, weight: .medium))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3.5)
                    .background(Color.cyan.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Compact Hover Content (Mode Hover / Dynamic Page Glance)
    
    @ViewBuilder
    private var compactHoverContent: some View {
        let hoverH = CGFloat(store.preferences.hoverHeight)
        let dividerH = max(20.0, hoverH - 22.0)
        let page = pageManager.currentCustomPage
        
        Group {
            switch page.layout {
            case .fullStage:
                NotchWidgetHostView(type: page.primaryWidget, size: .small)
                    .transition(.opacity)
                
            case .dualPod:
                HStack(spacing: 12) {
                    NotchWidgetHostView(type: page.primaryWidget, size: .small)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 1, height: dividerH)
                    
                    NotchWidgetHostView(type: page.secondaryWidget ?? .lyrics, size: .small)
                }
                .transition(.opacity)
                
            case .triplePod:
                HStack(spacing: 8) {
                    NotchWidgetHostView(type: page.primaryWidget, size: .small)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 1, height: dividerH)
                    
                    NotchWidgetHostView(type: page.secondaryWidget ?? .hardwareHUD, size: .small)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 1, height: dividerH)
                    
                    NotchWidgetHostView(type: page.tertiaryWidget ?? .quickTools, size: .small)
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: hoverH, alignment: .center)
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
                                    .foregroundColor(.cyan)
                                MarqueeText(
                                    lyric,
                                    fontSize: 9,
                                    fontWeight: .semibold,
                                    color: .cyan
                                )
                            }
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

// MARK: - MarqueeText (Auto-Scrolling Marquee Horizontal untuk Lirik & Teks Panjang)

public struct MarqueeText: View {
    public let text: String
    public var fontSize: CGFloat = 9.5
    public var fontWeight: Font.Weight = .semibold
    public var color: Color = .cyan
    public var alignment: Alignment = .leading
    
    @State private var isScrolling: Bool = false
    
    public init(
        _ text: String,
        fontSize: CGFloat = 9.5,
        fontWeight: Font.Weight = .semibold,
        color: Color = .cyan,
        alignment: Alignment = .leading
    ) {
        self.text = text
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.color = color
        self.alignment = alignment
    }
    
    private var nsFont: NSFont {
        let weight: NSFont.Weight
        switch fontWeight {
        case .bold: weight = .bold
        case .semibold: weight = .semibold
        case .medium: weight = .medium
        default: weight = .regular
        }
        let font = NSFont.systemFont(ofSize: fontSize, weight: weight)
        if let desc = font.fontDescriptor.withDesign(.rounded) {
            return NSFont(descriptor: desc, size: fontSize) ?? font
        }
        return font
    }
    
    private var textWidth: CGFloat {
        (text as NSString).size(withAttributes: [.font: nsFont]).width
    }
    
    public var body: some View {
        GeometryReader { geo in
            let containerWidth = geo.size.width
            let overflow = max(0, textWidth - containerWidth + 8)
            
            ZStack(alignment: alignment) {
                Text(text)
                    .font(.system(size: fontSize, weight: fontWeight, design: .rounded))
                    .foregroundColor(color)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .offset(x: isScrolling && overflow > 0 ? -overflow : 0)
                    .animation(
                        overflow > 0
                            ? Animation.easeInOut(duration: max(2.5, Double(overflow) / 18.0))
                                .delay(1.2)
                                .repeatForever(autoreverses: true)
                            : .default,
                        value: isScrolling
                    )
            }
            .frame(width: containerWidth, alignment: alignment)
            .clipped()
            .onAppear {
                if overflow > 0 {
                    isScrolling = true
                }
            }
        }
        .frame(height: fontSize + 4)
        .id(text)
    }
}
