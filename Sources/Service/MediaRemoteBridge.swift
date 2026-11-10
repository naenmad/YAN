import Foundation
import AppKit

private typealias MRGetNowPlayingInfoFunc = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
private typealias MRRegisterNotificationsFunc = @convention(c) (DispatchQueue) -> Void
private typealias MRSendCommandFunc = @convention(c) (Int32, AnyObject?) -> Bool

public final class MediaRemoteBridge {
    public static let shared = MediaRemoteBridge()
    
    private var getNowPlayingInfo: MRGetNowPlayingInfoFunc?
    private var registerForNotifications: MRRegisterNotificationsFunc?
    private var sendCommand: MRSendCommandFunc?
    
    private init() {
        loadFramework()
    }
    
    private func loadFramework() {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW) else {
            return
        }
        
        if let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") {
            getNowPlayingInfo = unsafeBitCast(sym, to: MRGetNowPlayingInfoFunc.self)
        }
        if let sym = dlsym(handle, "MRMediaRemoteRegisterForNowPlayingNotifications") {
            registerForNotifications = unsafeBitCast(sym, to: MRRegisterNotificationsFunc.self)
        }
        if let sym = dlsym(handle, "MRMediaRemoteSendCommand") {
            sendCommand = unsafeBitCast(sym, to: MRSendCommandFunc.self)
        }
        
        // Daftarkan listener notifikasi ke sistem
        registerForNotifications?(DispatchQueue.main)
    }
    
    public func fetchNowPlayingInfo(completion: @escaping ([String: Any]) -> Void) {
        guard let getInfo = getNowPlayingInfo else {
            completion([:])
            return
        }
        getInfo(DispatchQueue.main) { info in
            completion(info)
        }
    }
    
    // Commands: 0 = Play, 1 = Pause, 2 = TogglePlayPause, 4 = NextTrack, 5 = PreviousTrack
    public func togglePlayPause() {
        _ = sendCommand?(2, nil)
    }
    
    public func nextTrack() {
        _ = sendCommand?(4, nil)
    }
    
    public func previousTrack() {
        _ = sendCommand?(5, nil)
    }
}
