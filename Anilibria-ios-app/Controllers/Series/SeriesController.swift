//
//  SeriesController.swift
//  Anilibria-ios-app
//
//  Created by Mansur Nasybullin on 31.10.2023.
//

import UIKit

final class SeriesController: UIViewController, AnimeFlow, HasCustomView {
    typealias CustomView = SeriesView
    var navigator: AnimeNavigator?
    
    let contentController: SeriesContentController
    
    // MARK: LifeCycle
    init(data: AnimeItem) {
        contentController = SeriesContentController(data: data)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = SeriesView(delegate: contentController)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentController.delegate = self
    }
}

// MARK: - SeriesContentControllerDelegate

extension SeriesController: SeriesContentControllerDelegate {
    func didSelectItem(playlists: [Playlist], currentPlaylist: Int) {
        let player = VideoPlayerController.shared
        player.configure(playlist: playlists, currentPlaylist: currentPlaylist)
        present(player, animated: true)
    }
}
