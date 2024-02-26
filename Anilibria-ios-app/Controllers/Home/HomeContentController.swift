//
//  HomeContentController.swift
//  Anilibria-ios-app
//
//  Created by Mansur Nasybullin on 27.10.2023.
//

import UIKit
import SkeletonView

protocol HomeContentControllerDelegate: AnyObject {
    func todayHeaderButtonTapped()
    func youTubeHeaderButtonTapped(data: [HomePosterItem], rawData: [YouTubeAPIModel])
    func didSelectTodayItem(_ rawData: TitleAPIModel?, image: UIImage?)
    func didSelectUpdatesItem(_ rawData: TitleAPIModel?, image: UIImage?)
    func didSelectYoutubeItem(_ rawData: YouTubeAPIModel?)
    func dataIsApply()
}

@MainActor
final class HomeContentController: NSObject {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    
    enum Section: Int, CaseIterable {
        case today
        case watching
        case updates
        case youtube
    }
    
    enum Item: Hashable {
        case today(HomePosterItem, Section)
        case watching(HomeWatchingItem, Section)
        case updates(HomePosterItem, Section)
        case youtube(HomePosterItem, Section)
                
        var section: Section {
            switch self {
                case .today(_, let section):
                    return section
                case .watching(_, let section):
                    return section
                case .updates(_, let section):
                    return section
                case .youtube(_, let section):
                    return section
            }
        }
    }
    
    // MARK: Transition properties
    private (set) var selectedCell: PosterCollectionViewCell?
    private (set) var selectedCellImageViewSnapshot: UIView?
    
    weak var delegate: HomeContentControllerDelegate?
    
    private lazy var dataSource = makeDataSource()
    
    private let todayModel = HomeTodayModel()
    private let watchingModel = HomeWatchingModel()
    private let updatesModel = HomeUpdatesModel()
    private let youtubeModel = HomeYouTubeModel()
    
    private var todayData: [HomePosterItem] = []
    private var watchingData: [HomeWatchingItem] = []
    private var updatesData: [HomePosterItem] = []
    private var youtubeData: [HomePosterItem] = []
    
    private var isSkeletonView = true
    private var isLoadingData = false
    let customView: HomeView
    
    init(customView: HomeView, delegate: HomeContentControllerDelegate?) {
        self.customView = customView
        self.delegate = delegate
        super.init()
        
        setupCollectionView()
        setupModels()
        applySnapshot()
        customView.showSkeletonCollectionView()
        requestData()
    }
    
    func requestRefreshData() {
        guard isLoadingData == false else {
            customView.refreshControlEndRefreshing()
            return
        }
        requestData()
    }
}

// MARK: - Private methods
private extension HomeContentController {
    func setupCollectionView() {
        customView.collectionView.delegate = self
        customView.collectionView.prefetchDataSource = self
        customView.homeCollectionViewLayout.dataSource = dataSource
    }
    
    func setupModels() {
        [todayModel, updatesModel, youtubeModel].forEach {
            $0.imageModelDelegate = self
        }
        
        youtubeModel.downsampleSize = .init(width: 396, height: 222)
    }
    
    func todayCellRegistration() -> UICollectionView.CellRegistration<TodayHomePosterCollectionCell, Item> {
        UICollectionView.CellRegistration<TodayHomePosterCollectionCell, Item> { [weak self] cell, indexPath, _ in
            guard let item = self?.todayData[indexPath.row] else {
                return
            }
            
            if item.image == nil {
                self?.todayModel.requestImage(from: item.imageUrlString) { image in
                    self?.todayData[indexPath.row].image = image
                    cell.setImage(image, urlString: item.imageUrlString)
                }
            }
            cell.configureCell(item: item)
        }
    }
    
    func watchingCellRegistration() -> UICollectionView.CellRegistration<WatchingHomeCollectionViewCell, Item> {
        UICollectionView.CellRegistration<WatchingHomeCollectionViewCell, Item> { [weak self] cell, indexPath, _ in
            
            guard let item = self?.watchingData[indexPath.row] else {
                return
            }
            cell.configureCell(item: item)
        }
    }
    
    func updatesCellRegistration() -> UICollectionView.CellRegistration<UpdatesHomePosterCollectionCell, Item> {
        UICollectionView.CellRegistration<UpdatesHomePosterCollectionCell, Item> { [weak self] cell, indexPath, _ in
            guard let item = self?.updatesData[indexPath.row] else {
                return
            }
            
            if item.image == nil {
                self?.updatesModel.requestImage(from: item.imageUrlString) { image in
                    self?.updatesData[indexPath.row].image = image
                    cell.setImage(image, urlString: item.imageUrlString)
                }
            }
            cell.configureCell(item: item)
        }
    }
    
    func youtubeCellRegistration() -> UICollectionView.CellRegistration<YouTubeHomePosterCollectionCell, Item> {
        UICollectionView.CellRegistration<YouTubeHomePosterCollectionCell, Item> { [weak self] cell, indexPath, _ in
            guard let item = self?.youtubeData[indexPath.row] else {
                return
            }
            
            if item.image == nil {
                self?.youtubeModel.requestImage(from: item.imageUrlString) { image in
                    self?.youtubeData[indexPath.row].image = image
                    cell.setImage(image, urlString: item.imageUrlString)
                }
            }
            cell.configureCell(item: item)
        }
    }
    
    func makeDataSource() -> DataSource {
        let todayCellRegistration = todayCellRegistration()
        let watchingCellRegistration = watchingCellRegistration()
        let updatesCellRegistration = updatesCellRegistration()
        let youtubeCellRegistration = youtubeCellRegistration()
        
        let dataSource = HomeDiffableDataSource(
            collectionView: customView.collectionView,
            cellProvider: { (collectionView, indexPath, itemIdentifier) -> UICollectionViewCell? in
                let section = itemIdentifier.section
                
                switch section {
                    case .today:
                        return collectionView.dequeueConfiguredReusableCell(using: todayCellRegistration, for: indexPath, item: itemIdentifier)
                    case .watching:
                        return collectionView.dequeueConfiguredReusableCell(using: watchingCellRegistration, for: indexPath, item: itemIdentifier)
                    case .updates:
                        return collectionView.dequeueConfiguredReusableCell(using: updatesCellRegistration, for: indexPath, item: itemIdentifier)
                    case .youtube:
                        return collectionView.dequeueConfiguredReusableCell(using: youtubeCellRegistration, for: indexPath, item: itemIdentifier)
                }
            })
        
        dataSource.supplementaryViewProvider = { [weak self, weak dataSource] collectionView, kind, indexPath in
            guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HomeHeaderSupplementaryView.reuseIdentifier, for: indexPath) as? HomeHeaderSupplementaryView else {
                fatalError("Can`t create header view")
            }
            
            guard let section = dataSource?.sectionIdentifier(for: indexPath.section) else {
                fatalError("Section is not found in HomeContentController")
            }
            switch section {
                case .today:
                    headerView.configureView(
                        titleLabelText: Strings.HomeModule.Title.today,
                        titleButtonText: Strings.HomeModule.ButtonTitle.allDays) { [weak self] in
                            self?.delegate?.todayHeaderButtonTapped()
                        }
                case .watching:
                    headerView.configureView(titleLabelText: Strings.HomeModule.Title.watching)
                case .updates:
                    headerView.configureView(titleLabelText: Strings.HomeModule.Title.updates)
                case .youtube:
                    headerView.configureView(
                        titleLabelText: Strings.HomeModule.Title.youTube,
                        titleButtonText: Strings.HomeModule.ButtonTitle.all) { [weak self] in
                            guard let self else { return }
                            let rawData = youtubeModel.getRawData()
                            self.delegate?.youTubeHeaderButtonTapped(data: youtubeData, rawData: rawData)
                        }
            }
            return headerView
        }
        
        return dataSource
    }
    
    func applySnapshot(animatingDifferences: Bool = true) {
        var snapshot = Snapshot()
        
        var watchingArray = [Item]()
        watchingData.forEach {
            watchingArray.append(.watching($0, .watching))
        }
        
        var noImageData = [Item]()
        var todayArray = [Item]()
        todayData.forEach {
            let item = Item.today($0, .today)
            todayArray.append(item)
            if $0.image == nil {
                noImageData.append(item)
            }
        }
        var updatesArray = [Item]()
        updatesData.forEach {
            let item = Item.updates($0, .updates)
            updatesArray.append(item)
            if $0.image == nil {
                noImageData.append(item)
            }
        }
        var youtubeArray = [Item]()
        youtubeData.forEach {
            let item = Item.youtube($0, .youtube)
            youtubeArray.append(item)
            if $0.image == nil {
                noImageData.append(item)
            }
        }
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(todayArray, toSection: .today)
        if !watchingArray.isEmpty {
            snapshot.appendItems(watchingArray, toSection: .watching)
        } else {
            snapshot.deleteSections([.watching])
        }
        snapshot.appendItems(updatesArray, toSection: .updates)
        snapshot.appendItems(youtubeArray, toSection: .youtube)
        
        // for skeletonView. (Иначе пропадает skeleton на image)
        snapshot.reconfigureItems(noImageData)
        
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences) { [weak self] in
            self?.customView.refreshControlEndRefreshing()
            self?.delegate?.dataIsApply()
        }
    }
    
    func requestData() {
        isLoadingData = true
        Task(priority: .userInitiated) {
            defer {
                isLoadingData = false
            }
            do {
                async let today = todayModel.requestData()
                async let updates = updatesModel.requestData()
                async let youtube = youtubeModel.requestData()
                
                await todayData = try today
                await updatesData = try updates
                await youtubeData = try youtube
                
                customView.hideSkeletonCollectionView()
                applySnapshot()
            } catch {
                print(error)
            }
        }
    }
}

// MARK: - UICollectionViewDelegate

extension HomeContentController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let section = dataSource.sectionIdentifier(for: indexPath.section) else {
            fatalError("Section is not found in HomeContentController")
        }
        
        selectedCell = collectionView.cellForItem(at: indexPath) as? PosterCollectionViewCell
        selectedCellImageViewSnapshot = selectedCell?.imageView.snapshotView(afterScreenUpdates: false)
        
        let row = indexPath.row
        switch section {
            case .today:
                delegate?.didSelectTodayItem(
                    todayModel.getRawData(row: row),
                    image: todayData[row].image)
            case .watching:
                print("watching did selected")
            case .updates:
                delegate?.didSelectUpdatesItem(
                    updatesModel.getRawData(row: row),
                    image: updatesData[row].image)
            case .youtube:
                delegate?.didSelectYoutubeItem(youtubeModel.getRawData(row: row))
        }
    }
}

// MARK: - UICollectionViewDataSourcePrefetching

extension HomeContentController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            guard let section = dataSource.sectionIdentifier(for: indexPath.section) else {
                return
            }
            let row = indexPath.row
            switch section {
                case .today:
                    guard !todayData.isEmpty,
                          todayData[row].image == nil else { return }
                    let item = todayData[row]
                    todayModel.requestImage(from: item.imageUrlString) { [weak self] image in
                        self?.todayData[row].image = image
                    }
                case .watching:
                    break
                case .updates:
                    guard !updatesData.isEmpty,
                          updatesData[row].image == nil else { return }
                    let item = updatesData[row]
                    updatesModel.requestImage(from: item.imageUrlString) { [weak self] image in
                        self?.updatesData[row].image = image
                    }
                case .youtube:
                    guard !youtubeData.isEmpty,
                          youtubeData[row].image == nil else { return }
                    let item = youtubeData[row]
                    youtubeModel.requestImage(from: item.imageUrlString) { [weak self] image in
                        self?.youtubeData[row].image = image
                    }
            }
        }
    }
}

// MARK: - AnimePosterModelOutput

extension HomeContentController: ImageModelDelegate {
    func failedRequestImage(error: Error) {
        print(#function, error)
    }
}
