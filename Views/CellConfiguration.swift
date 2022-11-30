// Copyright 2016 Thomas Insam. All rights reserved.

import Foundation
import UIKit
import Utils

extension UICollectionViewListCell {

    public func configureWithTitle(_ title: String?, subtitle: String? = nil, vertical: Bool = true, highlight: Bool = false) {
        configurationUpdateHandler = { cell, state in
            guard let cell = cell as? UICollectionViewListCell else { return }
            var config = cell.defaultContentConfiguration()

            config.textProperties.font = UIFont.preferredFont(forTextStyle: .body)
            config.textProperties.color = .label
            config.textProperties.numberOfLines = 1

            config.secondaryTextProperties.font = UIFont.preferredFont(forTextStyle: .body)
            config.secondaryTextProperties.color = highlight ? cell.tintColor : .secondaryLabel
            config.secondaryTextProperties.numberOfLines = 1

            config.textToSecondaryTextVerticalPadding = 8

            if state.isFocused {
                // red background, fix visibility
                config.textProperties.color = .white
                config.secondaryTextProperties.color = .white
            }

            if vertical {
                config.directionalLayoutMargins = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
                config.prefersSideBySideTextAndSecondaryText = false
                cell.accessories = [.disclosureIndicator()]
            } else {
                config.directionalLayoutMargins = .init(top: 24, leading: 16, bottom: 24, trailing: 16)
                config.prefersSideBySideTextAndSecondaryText = true
                cell.accessories = []
            }

            config.text = title
            config.secondaryText = subtitle
            cell.contentConfiguration = config
        }
    }
}

extension UICollectionViewDiffableDataSource {
    public static func create(
        collectionView: UICollectionView,
        cellBinder: @escaping (UICollectionViewListCell, ItemIdentifierType) -> Void,
        headerTitleProvider: @escaping (SectionIdentifierType, Int) -> String? = { _, _ in nil }
    ) -> UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType> {

        let cellConfig = UICollectionView.CellRegistration<UICollectionViewListCell, ItemIdentifierType> { cell, _, item in
            cellBinder(cell, item)
        }

        let dataSource = UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>(collectionView: collectionView) { collectionView, indexPath, addressCluster in
            return collectionView.dequeueConfiguredReusableCell(using: cellConfig, for: indexPath, item: addressCluster)
        }

        let headerConfig = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { [weak dataSource] (headerView, _, indexPath) -> Void in
            guard let section = dataSource?.sectionIdentifier(for: indexPath.section) else { return }
            let count = dataSource?.snapshot().numberOfItems(inSection: section) ?? 0
            var configuration = headerView.defaultContentConfiguration()
            configuration.text = headerTitleProvider(section, count)
            headerView.contentConfiguration = configuration
        }

        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            if kind == UICollectionView.elementKindSectionHeader {
                return collectionView.dequeueConfiguredReusableSupplementary(using: headerConfig, for: indexPath)
            }
            assertionFailure()
            return nil
        }

        return dataSource
    }

}

extension UICollectionView {
    public static func createList(withHeaders: Bool) -> UICollectionView {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.headerMode = withHeaders ? .supplementary : .none
        return UICollectionView(
            frame: .zero,
            collectionViewLayout: UICollectionViewCompositionalLayout.list(using: configuration)
        )
    }
}
