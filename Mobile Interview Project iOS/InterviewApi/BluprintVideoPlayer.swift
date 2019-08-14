//
//  BluprintVideoPlayer.swift
//  Mobile Interview Project iOS
//
//  Created by John Owens on 8/7/19.
//  Copyright © 2019 Bluprint. All rights reserved.
//

import Foundation
import AVKit


/**
 * Interface for video player wrapper.
 * This protocol encapsulates all the functionality that is intentionally exposed
 * for the purpose of the project.
 */
protocol BluprintVideoPlayerType {
    func loadVideo(videoUrl: String)
    
    func addObserver(observer: BluprintVideoPlayerObserver)
    func removeObserver(observer: BluprintVideoPlayerObserver)
    func removeAllObservers()
}





final class BluprintVideoPlayer: NSObject, BluprintVideoPlayerType {
    private let player: AVQueuePlayer
    private var observations = [ObjectIdentifier : Observation]()
    
    private var playerItemContext = 0
    
    init(viewController: UIViewController,
         videoView: UIView) {
        self.player = AVQueuePlayer.init()
        super.init()
        
        player.actionAtItemEnd = .none
        let avPlayerController = AVPlayerViewController()
        avPlayerController.player = player
        avPlayerController.view.frame = videoView.bounds
        
        viewController.addChild(avPlayerController)
        videoView.addSubview(avPlayerController.view)
        
        NotificationCenter.default.addObserver(self, selector: #selector(BluprintVideoPlayer.itemPlaybackStalled),
                                               name: NSNotification.Name.AVPlayerItemPlaybackStalled, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BluprintVideoPlayer.itemPlayToEndTime),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVPlayerItemPlaybackStalled,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime,
                                                  object: nil)
    }
    
    func loadVideo(videoUrl: String) {
        player.addObserver(self,
                           forKeyPath: #keyPath(AVQueuePlayer.timeControlStatus),
                           options: [.old, .new],
                           context: &playerItemContext)
        
        if let url = URL(string: videoUrl) {
            let playerItem = AVPlayerItem.init(url: url)
            playerItem.addObserver(self,
                                   forKeyPath: #keyPath(AVPlayerItem.status),
                                   options: [.old, .new],
                                   context: &playerItemContext)
            playerItem.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
            playerItem.addObserver(self, forKeyPath: "playbackBufferFull", options: .new, context: nil)
            
            player.replaceCurrentItem(with: playerItem)
            player.play()
        }
    }
    
    func addObserver(observer: BluprintVideoPlayerObserver) {
        let id = ObjectIdentifier(observer)
        observations[id] = Observation(observer: observer)
    }
    
    func removeObserver(observer: BluprintVideoPlayerObserver) {
        let id = ObjectIdentifier(observer)
        observations.removeValue(forKey: id)
    }
    
    func removeAllObservers() {
        observations.removeAll()
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        
        if keyPath == "timeControlStatus", let change = change, let newValue = change[NSKeyValueChangeKey.newKey] as? Int, let oldValue = change[NSKeyValueChangeKey.oldKey] as? Int {
            let oldStatus = AVPlayer.TimeControlStatus(rawValue: oldValue)
            let newStatus = AVPlayer.TimeControlStatus(rawValue: newValue)
            if newStatus != oldStatus {
                DispatchQueue.main.async {[weak self] in
                    if(newStatus == .playing || newStatus == .paused) {
                        self?.emitUpdate(PlaybackState.ready)
                         return
                    }
                }
            }
        }
        
        if keyPath == "playbackBufferEmpty" {
            emitUpdate(PlaybackState.loading)
        }
        if keyPath == "playbackBufferFull" {
            emitUpdate(PlaybackState.ready)
        }
    }
    
    private func emitUpdate(_ updatedPlaybackState: PlaybackState) {
        for (id, observation) in observations {
            // If the observer is no longer in memory, we
            // can clean up the observation for its ID
            guard let observer = observation.observer else {
                observations.removeValue(forKey: id)
                continue
            }
            
            observer.playbackStateUpdate(player: player, newState: updatedPlaybackState)
        }
    }
    
    private func hasReallyReachedEndTime(player: AVPlayer) -> Bool {
        guard
            let duration = player.currentItem?.duration.seconds
            else { return false }
        
        /// item current time when receive end time notification
        /// is not so accurate according to duration
        /// added +1 make sure about the computation
        let currentTime = player.currentTime().seconds + 5
        return currentTime >= duration
    }
    
    @objc
    private func itemPlaybackStalled() {
        emitUpdate(PlaybackState.loading)
    }
    
    ///
    ///  AVPlayerItemDidPlayToEndTime notification can be triggered when buffer is empty and network is out.
    ///  We manually check if item has really reached his end time.
    ///
    @objc
    private func itemPlayToEndTime() {
        guard hasReallyReachedEndTime(player: player) else { return }
        emitUpdate(PlaybackState.ended)
    }
}

private extension BluprintVideoPlayer {
    struct Observation {
        weak var observer: BluprintVideoPlayerObserver?
    }
}
