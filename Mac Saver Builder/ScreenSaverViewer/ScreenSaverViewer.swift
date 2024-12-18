//
//  ScreenSaverViewer.swift
//  Mac Saver Builder
//
//  Created by Hüseyin Usta
//  Copyright © 2024 GetInfo. Licensed under MIT License.
//

import ScreenSaver
import AVKit

@objc(ScreenSaverViewer)
class ScreenSaverViewer: ScreenSaverView {
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerLooper: AVPlayerLooper?
    private var inactivityTimer: Timer?
    private let maxPlayDuration: TimeInterval = 900
    
    private lazy var videoURL: URL? = {
        let bundle = Bundle(for: type(of: self))
        guard let resourcePath = bundle.resourcePath,
              let files = try? FileManager.default.contentsOfDirectory(atPath: resourcePath),
              let videoFile = files.first(where: { $0.hasSuffix(".mp4") }),
              let videoPath = bundle.path(forResource: videoFile.replacingOccurrences(of: ".mp4", with: ""),
                                        ofType: "mp4") else {
            return nil
        }
        return URL(fileURLWithPath: videoPath)
    }()
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        
        wantsLayer = true
        layer = CALayer()
        layer?.backgroundColor = .black
        
        setupVideo()
        setupNotifications()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupNotifications()
    }
    
    private func setupVideo() {
        layer?.sublayers?.removeAll()

        guard let videoURL = videoURL else { return }
        
        let asset = AVURLAsset(url: videoURL)
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = 2.0
        
        player = AVQueuePlayer(playerItem: item)
        player?.automaticallyWaitsToMinimizeStalling = false
        playerLooper = AVPlayerLooper(player: player!, templateItem: item)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.frame = bounds
        
        player?.volume = 0.0
        
        layer?.addSublayer(playerLayer!)
        player?.play()
    }
    
    @MainActor private func enterLowPowerMode() {
        player?.pause()
        playerLayer?.opacity = 0
        cleanup()
    }
    
    override func startAnimation() {
        super.startAnimation()
        player?.play()
        
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: maxPlayDuration, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.enterLowPowerMode()
            }
        }
    }
    
    override func stopAnimation() {
        super.stopAnimation()
        inactivityTimer?.invalidate()
        inactivityTimer = nil
        cleanup()
    }
    
    private func cleanup() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        
        playerLooper?.disableLooping()
        playerLooper = nil
        
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        
        URLCache.shared.removeAllCachedResponses()
    }
    
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        playerLayer?.frame = bounds
    }
    
    deinit {
        Task { @MainActor [weak self] in
            self?.cleanup()
        }
    }
    
    private func setupNotifications() {
        DistributedNotificationCenter.default.addObserver(self,
            selector: #selector(handleScreensaverWillStop),
            name: Notification.Name("com.apple.screensaver.willstop"),
            object: nil)
        
        DistributedNotificationCenter.default.addObserver(self,
            selector: #selector(handleScreensaverDidStop),
            name: Notification.Name("com.apple.screensaver.didstop"),
            object: nil)
    }
    
    @objc private func handleScreensaverWillStop(_ notification: Notification) {
        print("Screensaver is about to stop.")
        cleanup()
    }
    
    @objc private func handleScreensaverDidStop(_ notification: Notification) {
        print("Screensaver did stop.")
    }
}

