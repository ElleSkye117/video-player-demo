//
//  ViewController.swift
//  Mobile Interview Project iOS
//
//  Created by Dusty Fields on 8/7/19.
//  Copyright © 2019 Bluprint. All rights reserved.
//

import AVKit
import UIKit

class ViewController: UIViewController {
    enum PlaylistFetchState {
        case loading
        case retry
        case refresh
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var currentStateButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var videoLoaderIndicator: UIActivityIndicatorView!
    
    // MARK: - Dependencies
    
    var player: BluprintVideoPlayer?
    let playlistFetcher = createNetworkApi()
    
    // MARK: - Private
    
    private var currentPlaylistFetchState: PlaylistFetchState = .loading {
        didSet {
            updateStatusButtonState()
        }
    }
    
    private var playlistItems: [PlaylistItemViewModel] = []
    private var currentlyPlaying: Int?
    
    
    deinit {
        player?.removeObserver(observer: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateStatusButtonState()
        refreshAll()
        videoLoaderIndicator.isHidden = true
        
        player = BluprintVideoPlayer(viewController: self, videoView: videoView)
        player?.addObserver(observer: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - IBActions
    
    @IBAction func refreshButtonTapped(_ sender: Any?) {
        guard currentPlaylistFetchState == .refresh else {
            return
        }
        refreshAll()
    }
    
    // MARK: - Private
    
    private func refreshAll() {
        currentPlaylistFetchState = .loading
        playlistFetcher.getInterviewPlaylist { [weak self] list in
            self?.fetchEpisodeMetaData(for: list)
        }
    }
    
    private func fetchEpisodeMetaData(for playlist: Playlist) {
        let group = DispatchGroup()
        
        var episodeMetaDatas: [EpisodeMetadata] = []
        var episodeAccessInfos: [EpisodeAccessInfo] = []
        var failed: Bool = false
        
        group.enter()
        group.enter()
        
        group.notify(queue: .main) {
            guard failed == false else {
                self.currentPlaylistFetchState = .retry
                self.playlistItems.removeAll()
                self.tableView.reloadData()
                return
            }
            // sort and make sure we match the right metadata with access info
            self.playlistItems = episodeMetaDatas.sorted().compactMap { metaData  -> PlaylistItemViewModel? in
                guard let foundMatch = episodeAccessInfos.first(where: { accessInfo in
                    return accessInfo.episodeId == metaData.episodeId
                }) else  {
                    return nil
                }
                return PlaylistItemViewModel(metaData: metaData, accessInfo: foundMatch)
            }

            self.currentPlaylistFetchState = .refresh
            self.tableView.reloadData()
        }
        
        playlistFetcher.getMetadataForEpisodes(episodeIds: playlist.episodeIds) { result in
            switch result {
            case .success(let data):
                episodeMetaDatas = data
            case .failure:
                failed = true
            }
            
            group.leave()
        }
        
        playlistFetcher.getEpisodeAccessInfos(episodeIds: playlist.episodeIds) { data in
            episodeAccessInfos = data
            
            group.leave()
        }
    }
    
    private func updateStatusButtonState() {
        switch currentPlaylistFetchState {
        case .loading:
            currentStateButton.setTitle("Loading...", for: .normal)
        case .refresh:
            currentStateButton.setTitle("Refresh", for: .normal)
        case .retry:
            currentStateButton.setTitle("Retry", for: .normal)
        }
    }
    
    private func playNext() {
        defer {
            tableView.reloadData()
        }
        
        guard let playingIndex = currentlyPlaying else {
            return
        }
        
        let currentVideo = playlistItems[playingIndex]

        let availableVideos = playlistItems.filter { $0.available }
        let availableIndexOptional = availableVideos.firstIndex { $0.metaData.episodeId == currentVideo.metaData.episodeId }
        guard var availableIndex = availableIndexOptional else {
            currentlyPlaying = nil
            return
        }
        
        availableIndex = availableIndex + 1
        
        // We were at the end
        guard availableIndex < availableVideos.count else {
            currentlyPlaying = nil
            return
        }
        
        // otherwise find the next available video
        let nextVideo = availableVideos[availableIndex]
        
        // look up the index in the full list
        currentlyPlaying = playlistItems.firstIndex { nextVideo.metaData.episodeId == $0.metaData.episodeId }
        
        player?.loadVideo(videoUrl: nextVideo.accessInfo.videoUrl)
    }
}


// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EpisodeTableViewCell", for: indexPath) as! PlaylistItemTableViewCell
        cell.viewModel = playlistItems[indexPath.row]
        cell.isPlaying = indexPath.row == currentlyPlaying
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlistItems.count
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let episodeModel = playlistItems[indexPath.row]
        guard episodeModel.available else {
            return
        }
        
        currentlyPlaying = indexPath.row
        player?.loadVideo(videoUrl: episodeModel.accessInfo.videoUrl)
        tableView.reloadData()
    }
}

// MARK: - BluprintVideoPlayerObserver

extension ViewController: BluprintVideoPlayerObserver {
    func playbackStateUpdate(player: AVPlayer, newState: PlaybackState) {
        switch newState {
        case .ended:
            playNext()
        case .loading:
            videoLoaderIndicator.isHidden = false
            videoLoaderIndicator.startAnimating()
        case .ready:
            videoLoaderIndicator.stopAnimating()
            videoLoaderIndicator.isHidden = true
        }
    }
}
