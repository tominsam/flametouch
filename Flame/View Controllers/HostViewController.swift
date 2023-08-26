// Copyright 2016 Thomas Insam. All rights reserved.

import RxSwift
import ServiceDiscovery
import UIKit
import Utils
import Views

/// View of a single host - lists the services of that host
class HostViewController: UIViewController, UICollectionViewDelegate {
    typealias DiffableDataSource = UICollectionViewDiffableDataSource<HostViewController.Section, HostViewController.Row>

    let serviceController: ServiceController
    let addressCluster: AddressCluster
    let disposeBag = DisposeBag()

    enum Section {
        case addresses
        case services
    }

    enum Row: Hashable {
        case address(String, Bool)
        case service(Service)
    }

    lazy var collectionView = UICollectionView.createList(withHeaders: true)

    lazy var dataSource = DiffableDataSource.create(
        collectionView: collectionView,
        cellBinder: { cell, item in
            switch item {
            case .address(let address, let alive):
                cell.configureWithTitle(address, vertical: false)
                cell.contentView.alpha = alive ? 1 : 0.3
            case .service(let service):
                cell.configureWithTitle(service.name, subtitle: service.typeWithDomain, vertical: true)
                cell.contentView.alpha = service.alive ? 1 : 0.3
            }
        }, headerTitleProvider: { section, count in
            switch section {
            case .addresses:
                return String(localized: "\(count) Addresses", comment: "Title of section containing addresses")
            case .services:
                return String(localized: "\(count) Services", comment: "Title of section containing services")
            }
        })

    required init(serviceController: ServiceController, addressCluster: AddressCluster) {
        self.serviceController = serviceController
        self.addressCluster = addressCluster
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        collectionView.dataSource = dataSource
        collectionView.delegate = self

        serviceController.services
            .host(forAddressCluster: addressCluster)
            .throttle(.milliseconds(200), scheduler: MainScheduler.instance)
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] host in
                guard let self else { return }
                updateHost(host)
            }
            .disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        for selected in collectionView.indexPathsForSelectedItems ?? [] {
            collectionView.deselectItem(at: selected, animated: true)
        }
    }

    func updateHost(_ host: Host) {
        title = host.name
        var snapshot = NSDiffableDataSourceSnapshot<Section, Row>()
        snapshot.appendSections([.addresses])
        snapshot.appendItems(host.addressCluster.sorted.map { .address($0, host.alive) })
        snapshot.appendSections([.services])
        snapshot.appendItems(host.displayServices.map { .service($0) })
        snapshot.reconfigureItems(snapshot.itemIdentifiers)
        dataSource.apply(snapshot, animatingDifferences: collectionView.frame.width > 0)
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let row = dataSource.itemIdentifier(for: indexPath) else { return false }
        switch row {
        case .address:
            return false
        case .service:
            return true
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let row = dataSource.itemIdentifier(for: indexPath) else { return }
        switch row {
        case .address:
            assertionFailure()
            collectionView.deselectItem(at: indexPath, animated: true)
        case .service(let service):
            let serviceController = ServiceViewController(serviceController: serviceController, service: service)
            show(serviceController, sender: self)
        }
    }

    func collectionView(_: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
        guard let row = dataSource.itemIdentifier(for: indexPath) else { return nil }
        switch row {
        case .address(let address, _):
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                let copyValueAction = UIAction(title: "Copy Address", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                    UIPasteboard.general.string = address
                }
                return UIMenu(title: "", children: [copyValueAction])
            }
        case .service(let service):
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                var actions = [UIAction]()
                actions.append(UIAction(title: "Copy Name", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                    UIPasteboard.general.string = service.name
                })
                actions.append(UIAction(title: "Copy Type", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                    UIPasteboard.general.string = service.type
                })
                if let url = service.url {
                    actions.append(UIAction(title: "Open", image: UIImage(systemName: "arrowshape.turn.up.right")) { [weak self] _ in
                        guard let self = self else { return }
                        AppDelegate.instance.openUrl(url, from: self)
                    })
                }

                return UIMenu(title: "", children: actions)
            }
        }
    }
}
