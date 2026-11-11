import SwiftUI
import AppKit
import AVFoundation

// MARK: - CameraPreviewView (Hardware-Accelerated Video Preview)

public struct CameraPreviewView: NSViewRepresentable {
    public let session: AVCaptureSession
    public var isMirrored: Bool
    
    public init(session: AVCaptureSession, isMirrored: Bool = true) {
        self.session = session
        self.isMirrored = isMirrored
    }
    
    public func makeNSView(context: Context) -> CameraPreviewNSView {
        let view = CameraPreviewNSView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.setMirrored(isMirrored)
        return view
    }
    
    public func updateNSView(_ nsView: CameraPreviewNSView, context: Context) {
        if nsView.previewLayer.session != session {
            nsView.previewLayer.session = session
        }
        nsView.setMirrored(isMirrored)
    }
}

public final class CameraPreviewNSView: NSView {
    public let previewLayer = AVCaptureVideoPreviewLayer()
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.addSublayer(previewLayer)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.addSublayer(previewLayer)
    }
    
    public override func layout() {
        super.layout()
        previewLayer.frame = bounds
    }
    
    public func setMirrored(_ mirrored: Bool) {
        if let connection = previewLayer.connection, connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = mirrored
        }
    }
}

// MARK: - NotchCameraView (Mode Clicked / 152pt)

public struct NotchCameraView: View {
    @ObservedObject private var camera = CameraManager.shared
    @State private var isShutterHovered: Bool = false
    @State private var isShutterPressed: Bool = false
    
    public init() {}
    
    private let viewfinderHeight: CGFloat = 118.0
    
    private var viewfinderWidth: CGFloat {
        round(viewfinderHeight * camera.aspectRatio.ratio)
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            // SISI KIRI: Live Viewfinder Murni (16:9 / 4:3)
            viewfinderSection
                .frame(width: viewfinderWidth, height: viewfinderHeight)
            
            // DIVIDER TENGAH
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1, height: 104)
            
            // SISI KANAN: Shutter & Kontrol Minimalis
            controlsSection
                .frame(maxWidth: .infinity, maxHeight: viewfinderHeight)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .onAppear {
            camera.startSession()
        }
        .onDisappear {
            camera.stopSession()
        }
    }
    
    // MARK: - Viewfinder Section (Murni, Bersih, Tanpa Overlay)
    
    private var viewfinderSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.80))
            
            if camera.hasPermission {
                if camera.isPaused {
                    VStack(spacing: 5) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.30))
                        Text("Paused")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.35))
                    }
                } else {
                    CameraPreviewView(session: camera.session, isMirrored: camera.isMirrored)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            } else if camera.isPermissionDenied {
                VStack(spacing: 6) {
                    Image(systemName: "camera")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.50))
                    
                    Button {
                        camera.openCameraPrivacySettings()
                    } label: {
                        Text("Open Settings")
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3.5)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button {
                    camera.requestPermission()
                } label: {
                    Text("Enable Camera")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            // Specular Border Rim
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            
            // White Shutter Flash
            if camera.snapshotFlash {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.90))
                    .transition(.opacity)
            }
        }
    }
    
    // MARK: - Controls Section (Sederhana & Rapi)
    
    private var controlsSection: some View {
        VStack(spacing: 8) {
            // Baris Atas: Hanya Ratio Picker [ 16:9 | 4:3 ] (Rapi, tanpa teks alay/titik ijo)
            HStack {
                Spacer()
                
                HStack(spacing: 1) {
                    ForEach(CameraAspectRatio.allCases) { item in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                camera.aspectRatio = item
                            }
                        } label: {
                            Text(item.rawValue)
                                .font(.system(size: 8, weight: camera.aspectRatio == item ? .bold : .medium))
                                .foregroundColor(camera.aspectRatio == item ? .white : .white.opacity(0.40))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(camera.aspectRatio == item ? Color.white.opacity(0.18) : Color.clear)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(1.5)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
            }
            
            Spacer(minLength: 0)
            
            // Bagian Tengah: Shutter Button Bersih
            VStack(spacing: 5) {
                Button {
                    isShutterPressed = true
                    camera.capturePhoto()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        isShutterPressed = false
                    }
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(Color.white.opacity(isShutterHovered ? 0.95 : 0.80), lineWidth: 2.5)
                            .frame(width: 48, height: 48)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 38, height: 38)
                            .overlay(
                                Image(systemName: camera.snapshotMessage != nil ? "checkmark" : "camera.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.black)
                            )
                    }
                    .scaleEffect(isShutterPressed ? 0.92 : (isShutterHovered ? 1.04 : 1.0))
                    .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isShutterPressed)
                    .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isShutterHovered)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isShutterHovered = hovering
                }
                
                Text(camera.snapshotMessage ?? "Take Photo")
                    .font(.system(size: 8.5, weight: camera.snapshotMessage != nil ? .bold : .medium, design: .rounded))
                    .foregroundColor(camera.snapshotMessage != nil ? .cyan : .white.opacity(0.45))
                    .animation(.easeInOut(duration: 0.2), value: camera.snapshotMessage)
            }
            
            Spacer(minLength: 0)
            
            // Baris Bawah: Dua Tombol Utility Sederhana
            HStack(spacing: 8) {
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        camera.toggleMirror()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 8.5))
                        Text(camera.isMirrored ? "Mirror" : "Natural")
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(camera.isMirrored ? .white : .white.opacity(0.50))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3.5)
                    .background(Color.white.opacity(camera.isMirrored ? 0.12 : 0.05))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        camera.togglePause()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: camera.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 7.5))
                        Text(camera.isPaused ? "Resume" : "Pause")
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(camera.isPaused ? .orange : .white.opacity(0.50))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3.5)
                    .background(Color.white.opacity(camera.isPaused ? 0.12 : 0.05))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - NotchCompactCameraView (Mode Hover / 56pt)

public struct NotchCompactCameraView: View {
    @ObservedObject private var camera = CameraManager.shared
    @ObservedObject private var store = NotchSettingsStore.shared
    @State private var isShutterHovered: Bool = false
    
    public init() {}
    
    public var body: some View {
        let hoverH = CGFloat(store.preferences.hoverHeight)
        let dividerH = max(20.0, hoverH - 26.0)
        
        HStack(spacing: 12) {
            // SISI KIRI: Mini Viewfinder Peek + Label Sederhana (Tanpa Titik Ijo)
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.black.opacity(0.60))
                    
                    if camera.hasPermission && !camera.isPaused {
                        CameraPreviewView(session: camera.session, isMirrored: camera.isMirrored)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    } else {
                        Image(systemName: "camera")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.50))
                    }
                    
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
                }
                .frame(width: 44, height: 26) // 16:9 mini peek (~44x26)
                
                Text("Mirror")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.90))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // DIVIDER TENGAH
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1, height: dividerH)
            
            // SISI KANAN: Compact Shutter Button
            HStack(spacing: 7) {
                Button {
                    camera.capturePhoto()
                } label: {
                    HStack(spacing: 5) {
                        ZStack {
                            Circle()
                                .strokeBorder(Color.white.opacity(0.85), lineWidth: 1.5)
                                .frame(width: 18, height: 18)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 12, height: 12)
                        }
                        
                        Text(camera.snapshotMessage ?? "Snap")
                            .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                            .foregroundColor(camera.snapshotMessage != nil ? .cyan : .white.opacity(0.85))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(isShutterHovered ? 0.12 : 0.06))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isShutterHovered = hovering
                }
            }
            .frame(width: 110, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, maxHeight: hoverH, alignment: .center)
        .padding(.horizontal, 10)
        .onAppear {
            camera.startSession()
        }
        .onDisappear {
            camera.stopSession()
        }
    }
}
