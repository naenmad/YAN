import Foundation
import AVFoundation
import AppKit
import SwiftUI

@MainActor
public final class CameraManager: NSObject, ObservableObject {
    public static let shared = CameraManager()
    
    // Status Kamera
    @Published public var isRunning: Bool = false
    @Published public var isPaused: Bool = false
    @Published public var isMirrored: Bool = true
    @Published public var hasPermission: Bool = false
    @Published public var isPermissionDenied: Bool = false
    @Published public var cameraName: String = "FaceTime HD Camera"
    
    // Snapshot Feedback
    @Published public var lastSnapshot: NSImage? = nil
    @Published public var snapshotFlash: Bool = false
    @Published public var snapshotMessage: String? = nil
    
    // AVFoundation Core
    public let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let sessionQueue = DispatchQueue(label: "com.yan.camera.sessionQueue", qos: .userInitiated)
    private var isConfigured = false
    
    private override init() {
        super.init()
        checkInitialPermission()
    }
    
    // MARK: - Permissions
    
    public func checkInitialPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            self.hasPermission = true
            self.isPermissionDenied = false
            configureSessionIfNeeded()
        case .denied, .restricted:
            self.hasPermission = false
            self.isPermissionDenied = true
        case .notDetermined:
            self.hasPermission = false
            self.isPermissionDenied = false
        @unknown default:
            break
        }
    }
    
    public func requestPermission(completion: ((Bool) -> Void)? = nil) {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            Task { @MainActor in
                self?.hasPermission = granted
                self?.isPermissionDenied = !granted
                if granted {
                    self?.configureSessionIfNeeded()
                    self?.startSession()
                }
                completion?(granted)
            }
        }
    }
    
    public func openCameraPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Session Configuration
    
    private func configureSessionIfNeeded() {
        guard !isConfigured else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            
            // 1. Video Device Input
            if let device = AVCaptureDevice.default(for: .video) {
                Task { @MainActor in
                    self.cameraName = device.localizedName
                }
                do {
                    let input = try AVCaptureDeviceInput(device: device)
                    if self.session.canAddInput(input) {
                        self.session.addInput(input)
                        self.videoDeviceInput = input
                    }
                } catch {
                    print("[CameraManager] Error creating device input: \(error)")
                }
            }
            
            // 2. Photo Output (untuk Snapshot Selfie)
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
                self.photoOutput.isHighResolutionCaptureEnabled = true
            }
            
            self.session.commitConfiguration()
            
            Task { @MainActor in
                self.isConfigured = true
            }
        }
    }
    
    // MARK: - Lifecycle (Start / Stop / Pause)
    
    public func startSession() {
        guard hasPermission, !isPaused else { return }
        configureSessionIfNeeded()
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
                Task { @MainActor in
                    self.isRunning = self.session.isRunning
                }
            }
        }
    }
    
    public func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                Task { @MainActor in
                    self.isRunning = false
                }
            }
        }
    }
    
    public func togglePause() {
        isPaused.toggle()
        if isPaused {
            stopSession()
        } else {
            startSession()
        }
    }
    
    public func toggleMirror() {
        isMirrored.toggle()
    }
    
    // MARK: - Photo Capture / Selfie Snapshot
    
    public func capturePhoto() {
        guard hasPermission, session.isRunning else {
            // Jika kamera belum aktif, aktifkan dulu sebentar
            if !session.isRunning && hasPermission {
                startSession()
            }
            return
        }
        
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    private func flipImageHorizontally(_ image: NSImage) -> NSImage {
        let size = image.size
        let flipped = NSImage(size: size)
        flipped.lockFocus()
        let transform = NSAffineTransform()
        transform.translateX(by: size.width, yBy: 0)
        transform.scaleX(by: -1, yBy: 1)
        transform.concat()
        image.draw(at: .zero, from: NSRect(origin: .zero, size: size), operation: .copy, fraction: 1.0)
        flipped.unlockFocus()
        return flipped
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    public nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let originalImage = NSImage(data: data) else {
            return
        }
        
        Task { @MainActor in
            let finalImage = self.isMirrored ? self.flipImageHorizontally(originalImage) : originalImage
            
            self.lastSnapshot = finalImage
            self.snapshotFlash = true
            self.snapshotMessage = "Copied to Clipboard!"
            
            // 1. Simpan ke Clipboard macOS
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.writeObjects([finalImage])
            
            // 2. Refresh ClipboardManager agar langsung muncul di halaman Clipboard
            ClipboardManager.shared.checkPasteboard()
            
            // 3. Suara shutter foto native macOS
            if let sound = NSSound(named: "camera_shutter") {
                sound.play()
            } else {
                NSSound.beep()
            }
            
            // 4. Reset flash & status message
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeOut(duration: 0.3)) {
                    self.snapshotFlash = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.snapshotMessage = nil
                }
            }
        }
    }
}
