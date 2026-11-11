import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Interactive Media Scrubber (Drag & Drop / Click to Seek)

public struct MediaScrubberView: View {
    public let duration: TimeInterval
    public let currentTime: TimeInterval
    public let onSeek: (TimeInterval) -> Void
    
    @State private var isDragging: Bool = false
    @State private var dragPosition: TimeInterval = 0
    @State private var isHovered: Bool = false
    
    public init(duration: TimeInterval, currentTime: TimeInterval, onSeek: @escaping (TimeInterval) -> Void) {
        self.duration = duration
        self.currentTime = currentTime
        self.onSeek = onSeek
    }
    
    private var displayTime: TimeInterval {
        isDragging ? dragPosition : currentTime
    }
    
    private var progress: Double {
        guard duration > 0, !duration.isNaN, !duration.isInfinite else { return 0.0 }
        return min(1.0, max(0.0, displayTime / duration))
    }
    
    public var body: some View {
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

// MARK: - Animated Audio Waveform Bars (Resting Notch Media)

public struct AudioWaveformBars: View {
    public let isPlaying: Bool
    @State private var bar1: CGFloat = 3
    @State private var bar2: CGFloat = 7
    @State private var bar3: CGFloat = 4
    
    public init(isPlaying: Bool) {
        self.isPlaying = isPlaying
    }
    
    public var body: some View {
        HStack(alignment: .bottom, spacing: 1.8) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.green)
                .frame(width: 2, height: bar1)
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.green)
                .frame(width: 2, height: bar2)
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.green)
                .frame(width: 2, height: bar3)
        }
        .frame(height: 10, alignment: .bottom)
        .onAppear {
            updateAnimation()
        }
        .onChange(of: isPlaying) { _ in
            updateAnimation()
        }
    }
    
    private func updateAnimation() {
        if isPlaying {
            withAnimation(.easeInOut(duration: 0.40).repeatForever(autoreverses: true)) {
                bar1 = 9
            }
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true).delay(0.12)) {
                bar2 = 10
            }
            withAnimation(.easeInOut(duration: 0.48).repeatForever(autoreverses: true).delay(0.06)) {
                bar3 = 8
            }
        } else {
            withAnimation(.easeOut(duration: 0.25)) {
                bar1 = 3
                bar2 = 4
                bar3 = 3
            }
        }
    }
}

// MARK: - NotchCanvasView

public struct NotchCanvasView: View {
    @ObservedObject var store: NotchSettingsStore = .shared
    @ObservedObject var media: MediaManager = .shared
    @ObservedObject var shelf: ShelfManager = .shared
    @ObservedObject var pageManager: NotchPageManager = .shared
    
    @State private var isHovered: Bool = false
    @State private var isExpanded: Bool = false
    
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
                            
                            AudioWaveformBars(isPlaying: track.isPlaying)
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 7)
                        .transition(.opacity)
                    }
                }
                
                // 4. Large Clicked State (580x148)
                if isExpanded {
                    VStack(spacing: 5) {
                        largeUnifiedContent
                        pageIndicatorBar
                    }
                    .padding(.bottom, 6)
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
            .gesture(
                TapGesture(count: 2).onEnded {
                    SettingsWindowController.shared.show()
                }
                .exclusively(
                    before: TapGesture(count: 1).onEnded {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isExpanded.toggle()
                        }
                    }
                )
            )
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
        .onReceive(NotificationCenter.default.publisher(for: .toggleNotchExpansion)) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isExpanded.toggle()
            }
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
        
        outsideLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { event in
            if event.type == .keyDown {
                if handleKeyDown(event: event) {
                    return nil
                }
                return event
            }
            handleOutsideClick(event: event)
            return event
        }
    }
    
    private func handleKeyDown(event: NSEvent) -> Bool {
        guard isExpanded else { return false }
        
        // Escape collapses the notch
        if event.keyCode == 53 {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                isExpanded = false
            }
            return true
        }
        
        // If editing in a text field or text view (e.g. scratchpad), do not intercept normal typing
        if let responder = NSApp.keyWindow?.firstResponder, responder is NSTextView || responder is NSTextField {
            return false
        }
        
        switch event.keyCode {
        case 123: // Left Arrow
            withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
                pageManager.previousPage()
            }
            return true
        case 124: // Right Arrow
            withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
                pageManager.nextPage()
            }
            return true
        case 18: // Number 1
            withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
                pageManager.switchToPage(index: 0)
            }
            return true
        case 19: // Number 2
            withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
                pageManager.switchToPage(index: 1)
            }
            return true
        case 20: // Number 3
            withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
                pageManager.switchToPage(index: 2)
            }
            return true
        case 21: // Number 4
            withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
                pageManager.switchToPage(index: 3)
            }
            return true
        default:
            return false
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
        let hasCamera = currentPage.slot1 == .camera
            || currentPage.slot2 == .camera
            || currentPage.slot3 == .camera
            || currentPage.slot4 == .camera
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
        let dividerHeight = max(60.0, currentH - 38)
        let page = pageManager.currentCustomPage
        
        Group {
            switch page.layout {
            case .dualPod:
                let podWidth = availableW / 2
                HStack(spacing: 14) {
                    NotchWidgetHostView(type: page.slot1, size: .medium)
                        .frame(width: podWidth)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 1, height: dividerHeight)
                    
                    NotchWidgetHostView(type: page.slot2 ?? .lyrics, size: .medium)
                        .frame(width: podWidth)
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .transition(.opacity)
                
            case .fullStage:
                NotchWidgetHostView(type: page.slot1, size: .large)
                    .frame(width: availableW)
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
                    .transition(.opacity)
                
            case .trio:
                // 1x (25%) + 1x (25%) + 2x (50%)
                let unitW = (availableW - 20) / 4
                HStack(spacing: 10) {
                    NotchWidgetHostView(type: page.slot1, size: .small)
                        .frame(width: unitW)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 1, height: dividerHeight)
                    
                    NotchWidgetHostView(type: page.slot2 ?? .hardwareHUD, size: .small)
                        .frame(width: unitW)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 1, height: dividerHeight)
                    
                    NotchWidgetHostView(type: page.slot3 ?? .quickTools, size: .medium)
                        .frame(width: unitW * 2)
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .transition(.opacity)
                
            case .quad:
                // 1x (25%) + 1x (25%) + 1x (25%) + 1x (25%)
                let unitW = (availableW - 30) / 4
                HStack(spacing: 10) {
                    NotchWidgetHostView(type: page.slot1, size: .small)
                        .frame(width: unitW)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 1, height: dividerHeight)
                    
                    NotchWidgetHostView(type: page.slot2 ?? .hardwareHUD, size: .small)
                        .frame(width: unitW)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 1, height: dividerHeight)
                    
                    NotchWidgetHostView(type: page.slot3 ?? .quickTools, size: .small)
                        .frame(width: unitW)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.10))
                        .frame(width: 1, height: dividerHeight)
                    
                    NotchWidgetHostView(type: page.slot4 ?? .scratchpad, size: .small)
                        .frame(width: unitW)
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .transition(.opacity)
            }
        }
    }
    
    // MARK: - Notch Page Indicator Bar
    
    @ViewBuilder
    private var pageIndicatorBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(pageManager.activePageIndex == index ? Color.cyan : Color.white.opacity(0.25))
                    .frame(
                        width: pageManager.activePageIndex == index ? 14 : 4.5,
                        height: 4
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            pageManager.switchToPage(index: index)
                        }
                    }
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.35))
                .overlay(
                    Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Compact Hover Content (Mode Hover / Dynamic Page Glance)
    
    @ViewBuilder
    private var compactHoverContent: some View {
        let hoverH = CGFloat(store.preferences.hoverHeight)
        let dividerH = max(18.0, hoverH - 26.0)
        let page = pageManager.currentCustomPage
        
        Group {
            switch page.layout {
            case .fullStage:
                NotchWidgetHostView(type: page.slot1, size: .small)
                    .transition(.opacity)
                
            case .dualPod:
                HStack(spacing: 12) {
                    NotchWidgetHostView(type: page.slot1, size: .small)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 1, height: dividerH)
                    
                    NotchWidgetHostView(type: page.slot2 ?? .lyrics, size: .small)
                }
                .transition(.opacity)
                
            case .trio:
                HStack(spacing: 8) {
                    NotchWidgetHostView(type: page.slot1, size: .small)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 1, height: dividerH)
                    
                    NotchWidgetHostView(type: page.slot2 ?? .hardwareHUD, size: .small)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 1, height: dividerH)
                    
                    NotchWidgetHostView(type: page.slot3 ?? .quickTools, size: .small)
                }
                .transition(.opacity)
                
            case .quad:
                HStack(spacing: 6) {
                    NotchWidgetHostView(type: page.slot1, size: .small)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 1, height: dividerH)
                    
                    NotchWidgetHostView(type: page.slot2 ?? .hardwareHUD, size: .small)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 1, height: dividerH)
                    
                    NotchWidgetHostView(type: page.slot3 ?? .quickTools, size: .small)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 1, height: dividerH)
                    
                    NotchWidgetHostView(type: page.slot4 ?? .scratchpad, size: .small)
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)
        .frame(maxWidth: .infinity, maxHeight: hoverH, alignment: .center)
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
