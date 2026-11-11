import SwiftUI
import AppKit
import AVFoundation

// MARK: - CameraPreviewView (Hardware-Accelerated CoreAnimation Video Preview)

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
    @State private var isButtonHovered: Bool = false
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 12) {
            // SISI KIRI: Live Camera Viewfinder (Mirror)
            viewfinderPod
                .frame(maxWidth: .infinity)
            
            // DIVIDER TENGAH
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1, height: 110)
            
            // SISI KANAN: Camera Controls & Snapshot
            controlsPod
                .frame(width: 210)
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
    
    // MARK: - Left Pod: Live Viewfinder
    
    private var viewfinderPod: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.60))
            
            if camera.hasPermission {
                if camera.isPaused {
                    // State: Kamera Dijedakan / Tertidur
                    VStack(spacing: 6) {
                        Image(systemName: "video.slash.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.40))
                        Text("Mirror Paused")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.50))
                    }
                } else {
                    // Live Hardware Camera Feed
                    CameraPreviewView(session: camera.session, isMirrored: camera.isMirrored)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            } else if camera.isPermissionDenied {
                // State: Izin Ditolak
                VStack(spacing: 8) {
                    Image(systemName: "camera.badge.ellipsis")
                        .font(.system(size: 22))
                        .foregroundColor(.yellow)
                    
                    Text("Camera Access Required")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Button {
                        camera.openCameraPrivacySettings()
                    } label: {
                        Text("Open Settings")
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
            } else {
                // State: Belum Meminta Izin
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.cyan)
                    
                    Text("Allow Camera Access")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Button {
                        camera.requestPermission()
                    } label: {
                        Text("Enable Mirror")
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.cyan)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Specular Border Rim
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            
            // Live Status Badge di Pojok Kiri Atas Viewfinder
            if camera.hasPermission && !camera.isPaused {
                VStack {
                    HStack {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 5, height: 5)
                            Text("LIVE")
                                .font(.system(size: 7.5, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Capsule())
                        
                        Spacer()
                        
                        Text(camera.isMirrored ? "MIRROR" : "NATURAL")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.75))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.50))
                            .clipShape(Capsule())
                    }
                    .padding(8)
                    
                    Spacer()
                }
            }
            
            // Flash Effect Saat Jepret Foto
            if camera.snapshotFlash {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.85))
                    .transition(.opacity)
            }
        }
    }
    
    // MARK: - Right Pod: Controls
    
    private var controlsPod: some View {
        VStack(alignment: .leading, spacing: 9) {
            // Header Info
            HStack(spacing: 5) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.cyan)
                
                Text("NOTCH MIRROR")
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.50))
                
                Spacer()
                
                // Device chip
                Text("FaceTime HD")
                    .font(.system(size: 7.5, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.60))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
            }
            
            // Tombol Utama: Take Selfie / Snapshot
            Button {
                camera.capturePhoto()
            } label: {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.cyan.opacity(0.20))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: camera.snapshotMessage != nil ? "checkmark" : "camera.shutter.button.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.cyan)
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(camera.snapshotMessage ?? "Take Selfie")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(camera.snapshotMessage != nil ? .cyan : .white)
                        
                        Text(camera.snapshotMessage != nil ? "Saved to Clipboard!" : "Copies photo to clipboard")
                            .font(.system(size: 7.5, weight: .regular))
                            .foregroundColor(.white.opacity(0.45))
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(isButtonHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.06))
                )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isButtonHovered = hovering
                }
            }
            .help("Snap a quick selfie and copy it to your clipboard")
            
            // Baris Tombol Sekunder: Flip Mirror & Sleep
            HStack(spacing: 6) {
                // Toggle Flip Mirror
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        camera.toggleMirror()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 9))
                            .foregroundColor(camera.isMirrored ? .cyan : .white.opacity(0.80))
                        Text(camera.isMirrored ? "Mirrored" : "Natural")
                            .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                            .foregroundColor(camera.isMirrored ? .cyan : .white.opacity(0.70))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(camera.isMirrored ? Color.cyan.opacity(0.14) : Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Toggle selfie mirror mode")
                
                // Toggle Sleep / Pause Camera
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        camera.togglePause()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: camera.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 8))
                            .foregroundColor(camera.isPaused ? .green : .white.opacity(0.70))
                        Text(camera.isPaused ? "Resume" : "Sleep")
                            .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                            .foregroundColor(camera.isPaused ? .green : .white.opacity(0.70))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(camera.isPaused ? Color.green.opacity(0.14) : Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Turn off camera sensor to conserve power")
            }
            
            Spacer(minLength: 0)
            
            // Privacy Hint Footer
            HStack(spacing: 4) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 7.5))
                    .foregroundColor(.green.opacity(0.80))
                Text("Camera turns off automatically when leaving page.")
                    .font(.system(size: 7.5, weight: .regular))
                    .foregroundColor(.white.opacity(0.35))
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - NotchCompactCameraView (Mode Hover / 56pt)

public struct NotchCompactCameraView: View {
    @ObservedObject private var camera = CameraManager.shared
    @ObservedObject private var store = NotchSettingsStore.shared
    @State private var isHovered: Bool = false
    
    public init() {}
    
    public var body: some View {
        let hoverH = CGFloat(store.preferences.hoverHeight)
        let dividerH = max(20.0, hoverH - 26.0)
        
        HStack(spacing: 12) {
            // SISI KIRI: Mini Viewfinder Peek + Label
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.black.opacity(0.50))
                    
                    if camera.hasPermission && !camera.isPaused {
                        CameraPreviewView(session: camera.session, isMirrored: camera.isMirrored)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.cyan)
                    }
                    
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.8)
                }
                .frame(width: 36, height: 36)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Notch Mirror")
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Circle()
                            .fill(camera.isRunning && !camera.isPaused ? Color.green : Color.orange)
                            .frame(width: 4, height: 4)
                    }
                    
                    Text(camera.cameraName)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // DIVIDER TENGAH
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: dividerH)
            
            // SISI KANAN: Quick Snap Button
            HStack(spacing: 8) {
                Button {
                    camera.capturePhoto()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: camera.snapshotMessage != nil ? "checkmark" : "camera.shutter.button.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.cyan)
                        Text(camera.snapshotMessage ?? "Quick Snap")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(camera.snapshotMessage != nil ? .cyan : .white)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5.5)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .frame(width: 140, alignment: .trailing)
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
