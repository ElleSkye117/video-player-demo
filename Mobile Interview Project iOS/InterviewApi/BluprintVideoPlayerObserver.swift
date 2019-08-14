//
//  BluprintVideoPlayerObserver.swift
//  Mobile Interview Project iOS
//
//  Created by John Owens on 8/8/19.
//  Copyright © 2019 Bluprint. All rights reserved.
//

import Foundation
import AVKit

enum PlaybackState {
    case ready
    case loading
    case ended
}

protocol BluprintVideoPlayerObserver: class {
    func playbackStateUpdate(player: AVPlayer,
                             newState: PlaybackState)
}
