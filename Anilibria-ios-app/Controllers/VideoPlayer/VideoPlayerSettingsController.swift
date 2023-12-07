//
//  VideoPlayerSettingsController.swift
//  Anilibria-ios-app
//
//  Created by Mansur Nasybullin on 05.12.2023.
//

import UIKit

protocol VideoPlayerSettingsControllerDelegate: AnyObject {
    func setRate(_ rate: Float)
    func setHLS(_ hls: HLS)
}

final class VideoPlayerSettingsController: UITableViewController {
    private enum Constants {
        static let cellIdentifier = "Cell"
    }
    
    private let hls: [HLS]
    private var currentHLS: HLS
    private var currentRate: PlayerRate
    private let data = PlayerSettingsRow.allCases
    
    weak var delegate: VideoPlayerSettingsControllerDelegate?
    
    init(hls: [HLS], currentHLS: HLS, rate: PlayerRate) {
        self.currentHLS = currentHLS
        self.hls = hls
        self.currentRate = rate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupNavigationItem()
    }
    
    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellIdentifier)
    }
    
    private func setupNavigationItem() {
        navigationItem.title = Strings.VideoPlayerSettings.settings
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeButtonDidTapped))
        navigationItem.rightBarButtonItem = closeButton
    }
    
    @objc private func closeButtonDidTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableView

extension VideoPlayerSettingsController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let rowInfo = PlayerSettingsRow.init(rawValue: indexPath.row) else {
            return
        }
        switch rowInfo {
            case .quality:
                let quailtyController = VideoPlayerSettingsDetailController<HLS>(data: hls, currentItem: currentHLS, title: Strings.VideoPlayerSettings.quality) { [weak self] selectedHLS in
                    self?.currentHLS = selectedHLS
                    self?.tableView.reloadData()
                    self?.delegate?.setHLS(selectedHLS)
                }
                navigationController?.pushViewController(quailtyController, animated: true)
            case .rate:
                let rateController = VideoPlayerSettingsDetailController<PlayerRate>(data: PlayerRate.allCases, currentItem: currentRate, title: Strings.VideoPlayerSettings.rate) { [weak self] selectedRate in
                    self?.currentRate = selectedRate
                    self?.tableView.reloadData()
                    self?.delegate?.setRate(selectedRate.rawValue)
                }
                navigationController?.pushViewController(rateController, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath)
        let item = data[indexPath.row]
        var configuration = UIListContentConfiguration.valueCell()
        configuration.text = item.description
        switch item {
            case .quality:
                configuration.secondaryText = currentHLS.description
            case .rate:
                configuration.secondaryText = currentRate.description
        }
        cell.contentConfiguration = configuration
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}
