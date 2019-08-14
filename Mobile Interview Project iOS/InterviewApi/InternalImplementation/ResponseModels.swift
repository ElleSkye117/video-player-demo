//
//  ResponseModels.swift
//  Mobile Interview Project iOS
//
//  Created by John Owens on 8/7/19.
//  Copyright © 2019 Bluprint. All rights reserved.
//

import Foundation

struct _PlaylistSummaryResponse: Codable {
    var playlistId: Int
    var title: String
    var episodes: [_EpisodeJson]
}

struct _EpisodeJson: Codable {
    var episodeId: Int
    var title: String
    var summary: String
    var contentLengthMs: Int
}

struct _VideoEndpointJson: Codable {
    var format: String?
    var url: String?
}
