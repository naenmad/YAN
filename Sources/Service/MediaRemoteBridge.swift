import Foundation
import AppKit

public struct NowPlayingPayload: Decodable {
    public let title: String?
    public let artist: String?
    public let album: String?
    public let duration: Double?
    public let elapsedTime: Double?
    public let playing: Bool?
    public let artworkData: String?
    public let bundleIdentifier: String?
    public let mediaType: String?
    
    public init(
        title: String? = nil,
        artist: String? = nil,
        album: String? = nil,
        duration: Double? = nil,
        elapsedTime: Double? = nil,
        playing: Bool? = nil,
        artworkData: String? = nil,
        bundleIdentifier: String? = nil,
        mediaType: String? = nil
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.elapsedTime = elapsedTime
        self.playing = playing
        self.artworkData = artworkData
        self.bundleIdentifier = bundleIdentifier
        self.mediaType = mediaType
    }
}

public struct NowPlayingMessage: Decodable {
    public let type: String?
    public let diff: Bool?
    public let payload: NowPlayingPayload?
}

public final class MediaRemoteBridge {
    public static let shared = MediaRemoteBridge()
    
    private var streamProcess: Process?
    private var stdoutPipe: Pipe?
    private var buffer = Data()
    
    // Direct C function for instant 0ms command execution & seeking
    private typealias MRSendCommandFunc = @convention(c) (Int32, AnyObject?) -> Bool
    private typealias MRSetElapsedTimeFunc = @convention(c) (Double) -> Void
    private var directSendCommand: MRSendCommandFunc?
    private var directSetElapsedTime: MRSetElapsedTimeFunc?
    
    public var onNowPlayingUpdate: ((NowPlayingPayload) -> Void)?
    
    private init() {
        setupDirectCommands()
    }
    
    private func setupDirectCommands() {
        if let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW) {
            if let sym = dlsym(handle, "MRMediaRemoteSendCommand") {
                directSendCommand = unsafeBitCast(sym, to: MRSendCommandFunc.self)
            }
            if let sym = dlsym(handle, "MRMediaRemoteSetElapsedTime") {
                directSetElapsedTime = unsafeBitCast(sym, to: MRSetElapsedTimeFunc.self)
            }
        }
    }
    
    public func startStream() {
        stopStream()
        
        guard let (scriptURL, frameworkURL) = resolveAdapterPaths() else {
            print("[MediaRemoteBridge] Adapter paths not found")
            return
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        process.arguments = [scriptURL.path, frameworkURL.path, "stream", "--no-diff"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe() // Suppress stderr
        
        self.stdoutPipe = pipe
        self.streamProcess = process
        
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            self?.processIncomingData(data)
        }
        
        process.terminationHandler = { [weak self] _ in
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.startStream()
            }
        }
        
        do {
            try process.run()
        } catch {
            print("[MediaRemoteBridge] Failed to launch adapter stream: \(error)")
        }
    }
    
    public func stopStream() {
        stdoutPipe?.fileHandleForReading.readabilityHandler = nil
        stdoutPipe = nil
        if let proc = streamProcess, proc.isRunning {
            proc.terminate()
        }
        streamProcess = nil
    }
    
    private func processIncomingData(_ data: Data) {
        buffer.append(data)
        while let newlineRange = buffer.range(of: Data([0x0A])) { // \n
            let lineData = buffer.subdata(in: 0..<newlineRange.lowerBound)
            buffer.removeSubrange(0..<newlineRange.upperBound)
            
            if let message = try? JSONDecoder().decode(NowPlayingMessage.self, from: lineData),
               let payload = message.payload {
                DispatchQueue.main.async { [weak self] in
                    self?.onNowPlayingUpdate?(payload)
                }
            }
        }
    }
    
    private func resolveAdapterPaths() -> (scriptURL: URL, frameworkURL: URL)? {
        let possibleDirs: [URL?] = [
            Bundle.main.resourceURL?.appendingPathComponent("mediaremote-adapter"),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/mediaremote-adapter"),
            URL(fileURLWithPath: "/Users/mac/Developer/YAN Another Notch/Resources/mediaremote-adapter")
        ]
        
        for dir in possibleDirs {
            guard let dir = dir else { continue }
            let script = dir.appendingPathComponent("mediaremote-adapter.pl")
            let framework = dir.appendingPathComponent("MediaRemoteAdapter.framework")
            if FileManager.default.fileExists(atPath: script.path) && FileManager.default.fileExists(atPath: framework.path) {
                return (script, framework)
            }
        }
        return nil
    }
    
    // Commands: 0 = Play, 1 = Pause, 2 = TogglePlayPause, 4 = NextTrack, 5 = PreviousTrack
    public func togglePlayPause() {
        if directSendCommand?(2, nil) != true {
            executeFallbackCommand(id: 2)
        }
    }
    
    public func play() {
        if directSendCommand?(0, nil) != true {
            executeFallbackCommand(id: 0)
        }
    }
    
    public func pause() {
        if directSendCommand?(1, nil) != true {
            executeFallbackCommand(id: 1)
        }
    }
    
    public func nextTrack() {
        if directSendCommand?(4, nil) != true {
            executeFallbackCommand(id: 4)
        }
    }
    
    public func previousTrack() {
        if directSendCommand?(5, nil) != true {
            executeFallbackCommand(id: 5)
        }
    }
    
    public func seek(to seconds: Double) {
        if let setTime = directSetElapsedTime {
            setTime(seconds)
        }
        let micros = Int64(seconds * 1_000_000)
        executeFallbackSeek(micros: micros)
    }
    
    private func executeFallbackSeek(micros: Int64) {
        guard let (scriptURL, frameworkURL) = resolveAdapterPaths() else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
            proc.arguments = [scriptURL.path, frameworkURL.path, "seek", "\(micros)"]
            try? proc.run()
        }
    }
    
    private func executeFallbackCommand(id: Int32) {
        guard let (scriptURL, frameworkURL) = resolveAdapterPaths() else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
            proc.arguments = [scriptURL.path, frameworkURL.path, "send", "\(id)"]
            try? proc.run()
        }
    }
}
