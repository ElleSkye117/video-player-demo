//
//  NetworkApiImpl.swift
//  Mobile Interview Project iOS
//
//  Created by John Owens on 8/7/19.
//  Copyright © 2019 Bluprint. All rights reserved.
//

import Foundation

class _NetworkApiImpl: NetworkApi {
    private static var internalPlaylistModel: _InternalPlaylistModel!
    
    func getInterviewPlaylist(responseCallback: @escaping (Playlist) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 1500...2500))) {
            let playlist = Playlist(id: _NetworkApiImpl.internalPlaylistModel.id,
                                    title: _NetworkApiImpl.internalPlaylistModel.title,
                                    episodeIds: _NetworkApiImpl.internalPlaylistModel.episodes.map({ $0.id }))
            responseCallback(playlist)
        }
    }
    
    func getEpisodeAccessInfos(episodeIds: [Int], responseCallback: @escaping ([EpisodeAccessInfo]) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 1500...2500))) {
            let matchingInternalEpisodes = _NetworkApiImpl.internalPlaylistModel.episodes.filter({ episodeIds.contains($0.id) })
            
            let matchingEpisodeAccessInfos = matchingInternalEpisodes.map { internalEpisode in
                EpisodeAccessInfo(episodeId: internalEpisode.id,
                                  videoUrl: internalEpisode.userHasAccess ? internalEpisode.videoUrl : "<NO_ACCESS>",
                                  userHasAccess: internalEpisode.userHasAccess)
            }
            responseCallback(matchingEpisodeAccessInfos)
        }
    }
    
    func getMetadataForEpisodes(episodeIds: [Int], responseCallback: @escaping (ApiResult<[EpisodeMetadata]>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int.random(in: 1500...2500))) {
            let shouldFail = Int.random(in: 0...100) > 80
            if shouldFail {
                responseCallback(ApiResult.failure)
            } else {
                let matchingInternalEpisodes = _NetworkApiImpl.internalPlaylistModel.episodes.filter({ episodeIds.contains($0.id) })
                
                let matchingEpisodeAccessInfos = matchingInternalEpisodes.map { internalEpisode in
                    EpisodeMetadata(episodeId: internalEpisode.id,
                                    title: internalEpisode.title,
                                    indexInPlaylist: internalEpisode.indexInPlaylist,
                                    featuredEpisode: internalEpisode.featuredEpisode)
                }
                responseCallback(ApiResult.success(matchingEpisodeAccessInfos))
            }
        }
    }
    
    class func loadInternal() {
        _NetworkApiImpl.generateInternalPlaylistModel()
        do { _NetworkApiImpl.internalPlaylistModel.id } catch let error {
            print("InternalPlaylistModel not properly initialized. Are you connected to the internet?", error)
        }
    }
    
    private class func generateInternalPlaylistModel() {
        let semaphore = DispatchSemaphore(value: 0)
    
        let url = Bundle.main.url(forResource: "playlist", withExtension: "json")!
        let jsonData = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        
        let playlistSummaryJson = try! decoder.decode(_PlaylistSummaryResponse.self, from: jsonData)
        
        var threeUniqueIndices: Set<Int> = []
        while(threeUniqueIndices.count < 3) {
            threeUniqueIndices.insert(Int.random(in: 0..<playlistSummaryJson.episodes.count))
        }
        let shuffledList = threeUniqueIndices.shuffled()
        
        let featuredEpisodeIndex = shuffledList[0]
        let episodeIndicesWithoutAccess = [shuffledList[1], shuffledList[2]]
        
        let episodeIds = playlistSummaryJson.episodes.map({ $0.episodeId })
        determineVideoUrls(episodeIds: episodeIds) { episodeIdsToUrlsDict in
            let episodesWithMatchingUrls = playlistSummaryJson.episodes.filter({episodeIdsToUrlsDict[$0.episodeId] != nil} )
            
            let internalEpisodes = episodesWithMatchingUrls.enumerated()
                .map{ (indexWithEpisode) -> _InternalPlaylistModel.Episode in
                    let (index, episode) = indexWithEpisode
                    return _InternalPlaylistModel.Episode(id: episode.episodeId,
                                                          title: episode.title,
                                                          summary: episode.summary,
                                                          indexInPlaylist: index,
                                                          featuredEpisode: index == featuredEpisodeIndex,
                                                          videoUrl: episodeIdsToUrlsDict[episode.episodeId]!,
                                                          userHasAccess: !episodeIndicesWithoutAccess.contains(index))
                    
            }
            
            internalPlaylistModel = _InternalPlaylistModel(id: playlistSummaryJson.playlistId,
                                                           title: playlistSummaryJson.title,
                                                           episodes: internalEpisodes)
            semaphore.signal()
        }
        
        semaphore.wait(timeout: DispatchTime.now() + .seconds(30))
    }
    
    private class func determineVideoUrls(episodeIds: [Int], completion: @escaping ([Int: String]) -> Void){
        let deviceId = UUID().uuidString
        
        DispatchQueue.global(qos: .userInteractive).sync {
            let startUrl = URL(string: "https://api.newco.sympoz.net/m/sneakPreviewStartRequests")!
            var startRequest = URLRequest(url: startUrl)
            startRequest.httpMethod = "POST"
            startRequest.setValue("Application/json", forHTTPHeaderField: "Content-Type")
            startRequest.httpBody = try! JSONSerialization.data(withJSONObject: ["deviceId": deviceId], options: [])
            
            URLSession.shared.dataTask(with: startRequest) { (data, response, error) in
                
                var episodeIdToUrlDict: [Int: String] = [:]
                let episodeUrlGroup = DispatchGroup()
                
                DispatchQueue.concurrentPerform(iterations: episodeIds.count) { index in
                    episodeUrlGroup.enter()
                    
                    let episodeId = episodeIds[index]
                    var url: URL? {
                        var components = URLComponents()
                        components.scheme = "https"
                        components.host = "api.newco.sympoz.net"
                        components.path = "/m/videos/sneakPreview/episodes/\(episodeId)"
                        components.queryItems = [URLQueryItem(name: "deviceId", value: deviceId)]
                        return components.url
                    }
                    
                    URLSession.shared.dataTask(with: url!) {(data, response, error) in
                        do {
                            let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: [])
                            let jsonArray = jsonResponse as! [[String: Any]]
                            let url = jsonArray[0]["url"] as! String
                            episodeIdToUrlDict[episodeId] = url
                            episodeUrlGroup.leave()
                        } catch let error {
                            print("Error parsing video url", error)
                            episodeUrlGroup.leave()
                        }
                        }.resume()
                }
                
                episodeUrlGroup.notify(queue: DispatchQueue.global(qos: .userInteractive)) {
                    completion(episodeIdToUrlDict)
                }
                }.resume()
        }
    }
}
