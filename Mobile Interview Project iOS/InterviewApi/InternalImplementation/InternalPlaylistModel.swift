//
//  InternalPlaylistModel.swift
//  Mobile Interview Project iOS
//
//  Created by John Owens on 8/7/19.
//  Copyright © 2019 Bluprint. All rights reserved.
//

import Foundation

struct _InternalPlaylistModel {
    let id: Int
    let title: String
    let episodes: [Episode]
    
    struct Episode {
        let id: Int
        let title: String
        let summary: String
        let indexInPlaylist: Int
        let featuredEpisode: Bool
        let videoUrl: String
        let userHasAccess: Bool
    }
}
