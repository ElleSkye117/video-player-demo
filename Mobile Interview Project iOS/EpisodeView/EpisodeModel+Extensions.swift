extension EpisodeMetadata: Comparable {
    static func < (lhs: EpisodeMetadata, rhs: EpisodeMetadata) -> Bool {
        return lhs.indexInPlaylist < rhs.indexInPlaylist
    }
}
extension EpisodeMetadata: Equatable {
    static func == (lhs: EpisodeMetadata, rhs: EpisodeMetadata) -> Bool {
        return lhs.episodeId == rhs.episodeId
    }
}

extension EpisodeAccessInfo: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(episodeId)
    }
}

extension EpisodeAccessInfo: Equatable {
    static func == (lhs: EpisodeAccessInfo, rhs: EpisodeAccessInfo) -> Bool {
        return lhs.episodeId == rhs.episodeId
    }
}

