//
//  EpisodeListViewModel.swift
//  Mobile Interview Project iOS
//
//  Created by MLeber on 8/13/19.
//  Copyright © 2019 Bluprint. All rights reserved.
//

import Foundation
class PlaylistItemViewModel {
    let metaData: EpisodeMetadata
    let accessInfo: EpisodeAccessInfo
    
    var playing: Bool = false
    var title: String {
        return metaData.title
    }
    
    var statusText: String {
        guard metaData.featuredEpisode else {
            return accessInfo.userHasAccess ? "Available" : "Unavailable"
        }
        return "Featured"
    }
    var available: Bool {
        return accessInfo.userHasAccess || metaData.featuredEpisode
    }
    
    init(metaData: EpisodeMetadata, accessInfo: EpisodeAccessInfo) {
        self.metaData = metaData
        self.accessInfo = accessInfo
    }
}
