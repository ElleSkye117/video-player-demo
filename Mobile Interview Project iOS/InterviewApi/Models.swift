//
//  Models.swift
//  Mobile Interview Project iOS
//
//  Created by John Owens on 8/7/19.
//  Copyright © 2019 Bluprint. All rights reserved.
//

import Foundation

struct Playlist {
    let id: Int
    let title: String
    let episodeIds: [Int]
}

struct EpisodeAccessInfo {
    let episodeId: Int
    let videoUrl: String
    let userHasAccess: Bool
}

struct EpisodeMetadata {
    let episodeId: Int
    let title: String
    let indexInPlaylist: Int
    let featuredEpisode: Bool
}
