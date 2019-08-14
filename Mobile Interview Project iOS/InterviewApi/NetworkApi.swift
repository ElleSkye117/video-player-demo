//
//  NetworkApi.swift
//  Mobile Interview Project iOS
//
//  Created by John Owens on 8/7/19.
//  Copyright © 2019 Bluprint. All rights reserved.
//

import Foundation


/**
 * Api for performing requests that would normally be performed over the network
 *
 * To create an instance of this API simply write: createNetworkApi()
 *
 * Example usage:
 *      let networkApi = createNetworkApi()
 *      let episodeIds = [1, 2, 3]
 *      networkApi.getEpisodeAccessInfos(episodeIds) { episodeAccessInfos in
 *          ...
 *      }
 */
protocol NetworkApi {
    
    func getInterviewPlaylist(responseCallback: @escaping (Playlist) -> Void)
    
    func getEpisodeAccessInfos(episodeIds: [Int], responseCallback: @escaping ([EpisodeAccessInfo]) -> Void)
    
    func getMetadataForEpisodes(episodeIds: [Int], responseCallback: @escaping (ApiResult<[EpisodeMetadata]>) -> Void)
    
}

func createNetworkApi() -> NetworkApi {
    return _NetworkApiImpl()
}
