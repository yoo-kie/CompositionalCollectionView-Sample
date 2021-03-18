//
//  ViewController.swift
//  CollectionViewLayout-Practice
//
//  Created by 유연주 on 2021/03/07.
//

import UIKit

class ViewController: UIViewController {
    
    /// Section : UICollectionView가 가질 섹션들을 정의해놓은 열거형
    enum Section: CaseIterable {
        case basic
        case list
        case outline
    }
    
    /// Item : 셀 하나를 구성할 아이템 데이터 구조체
    ///     identifier : Diffable data에 들어가는 item은 모두 유니크한 identifier를 가져야 함
    ///     title : 이모지 이름
    ///     emoji : 현재 아이템의 이모지 정보
    ///     hasChildren : 상위 카테고리인지 알려주는 flag값
    struct Item: Hashable {
        private let identifier = UUID()
        let title: String?
        let emoji: Emoji?
        let hasChildren: Bool
        
        init(emoji: Emoji? = nil, title: String? = nil, hasChildren: Bool = false) {
            self.emoji = emoji
            self.title = title
            self.hasChildren = hasChildren
        }
    }
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureHierarchy()
        configureDataSource()
        applyInitialSnapshots()
    }
    
    // MARK: - UICollectionView 추가

    func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        view.addSubview(collectionView)
    }
    
    // MARK: - UICollectionViewCompositionalLayout
    
    /// UICollectionViewComposotionalLayout : item들을 시각적으로 정렬돼 보이게 배치해주는 UICollectionView 레이아웃 객체
    func createLayout() -> UICollectionViewLayout {
        /// UICollectionViewCompositionalLayoutSectionProvider : 각 레이아웃의 섹션을 생성하고 반환하는 클로저 (**섹션을 반환하는 것**)
        let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            let section: NSCollectionLayoutSection
            let sectionType = Section.allCases[sectionIndex]
            
            switch sectionType {
            /// item -> group -> section
            case .basic:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(0.2))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary // 스크롤 좌우 방향
            
            /// UICollectionLayoutListConfiguration : 테이블뷰와 비슷하게 생긴 list 레이아웃
            case .list:
                let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
                
            case .outline:
                let configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
                section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
            }
            
            section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            
            return section
        }
        
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
    }
    
    // MARK: - CellRegistration & UICollectionViewDiffableDataSource
    
    /// UICollectionViewCellRegistration : collectionView의 셀 register를 담당하며, cellType과 ItemType을 정의해 해당 셀의 content와 appearance를 설정
    /// UICollectionViewDiffableDataSource : collectionVIew의 data와 UI를 업데이트함
    /// cellProvider를 DiffableDataSource에 넘겨줌으로써 해당 collectionView Section의 셀 data와 UI를 지정해줌
    func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { (cell, indexPath, item) in
            var contentConfiguration = cell.defaultContentConfiguration()
            contentConfiguration.text = item.emoji?.text
            contentConfiguration.textProperties.font = .boldSystemFont(ofSize: 35)
            contentConfiguration.textProperties.alignment = .center
            cell.contentConfiguration = contentConfiguration
            
            var backgroundConfiguration = UIBackgroundConfiguration.listPlainCell()
            backgroundConfiguration.cornerRadius = 10
            backgroundConfiguration.strokeColor = .black
            cell.backgroundConfiguration = backgroundConfiguration
        }
        
        let listCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { (cell, indexPath, item) in
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.text = item.emoji?.text
            contentConfiguration.secondaryText = item.emoji?.title
            cell.contentConfiguration = contentConfiguration
        }
        
        let outlineHeaderCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { (cell, indexPath, item) in
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            cell.contentConfiguration = content
            cell.accessories = [.outlineDisclosure(options: .init(style: .header))]
        }
        
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) {
            (collectionView, indexPath, item) -> UICollectionViewCell? in
            let sectionType = Section.allCases[indexPath.section]
            
            switch sectionType {
            case .basic:
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
                
            case .list:
                return collectionView.dequeueConfiguredReusableCell(using: listCellRegistration, for: indexPath, item: item)
                
            case .outline:
                if item.hasChildren {
                    return collectionView.dequeueConfiguredReusableCell(using: outlineHeaderCellRegistration, for: indexPath, item: item)
                } else {
                    return collectionView.dequeueConfiguredReusableCell(using: listCellRegistration, for: indexPath, item: item)
                }
            }
        }
    }
    
    // MARK: - NSDiffableDataSourceSnapshot
    
    /// NSDiffableDataSourceSnapshot : 특정 시점의 data 상태를 나타냄 / 초기 data를 설정하고 추후에 data를 업데이트 할 수 있음
    /// 즉, data를 추가하고 삭제하고 이동시키며 섹션과 item들에 보여지는 것들을 설정할 수 있음
    func applyInitialSnapshots() {
        let sections = Section.allCases
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(sections)
        dataSource.apply(snapshot)
        
        var basicSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        basicSnapshot.append(Emoji.Category.recents.emojis.map { Item(emoji: $0) })
        dataSource.apply(basicSnapshot, to: .basic, animatingDifferences: false)
        
        var listSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        listSnapshot.append(Emoji.Category.food.emojis.map { Item(emoji: $0) })
        dataSource.apply(listSnapshot, to: .list, animatingDifferences: false)
        
        var outlineSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        let emojiCategories = Emoji.Category.allCases.filter { $0 != .recents }
        emojiCategories.forEach {
            let headerItem = Item(title: String(describing: $0), hasChildren: true)
            outlineSnapshot.append([headerItem])
            outlineSnapshot.append($0.emojis.map { Item(emoji: $0) }, to: headerItem)
        }
        dataSource.apply(outlineSnapshot, to: .outline, animatingDifferences: false)
    }
    
}

extension ViewController: UICollectionViewDelegate {
    
}
