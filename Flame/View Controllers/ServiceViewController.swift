// Copyright 2016 Thomas Insam. All rights reserved.

import RxSwift
import ServiceDiscovery
import UIKit
import Utils
import Views
import SnapKit

/// Shows the details of a particular service on a particular host
class ServiceViewController: UIViewController, UICollectionViewDelegate {
    typealias DiffableDataSource = UICollectionViewDiffableDataSource<ServiceViewController.Section, ServiceViewController.Row>

    let serviceController: ServiceController
    let disposeBag = DisposeBag()

    var service: Service
    var alive = true

    enum Section {
        case core
        case data
    }

    struct Row: Hashable {
        let name: String
        let value: String
    }

    lazy var collectionView = UICollectionView.createList(withHeaders: true)

    lazy var dataSource = DiffableDataSource.create(
        collectionView: collectionView,
        cellBinder: { [weak self] cell, item in
            cell.configureWithTitle(item.name, subtitle: item.value, vertical: false, highlight: self?.urlFor(item: item) != nil)
            cell.contentView.alpha = self?.alive == true ? 1 : 0.3
        }, headerTitleProvider: { section, _ in
            switch section {
            case .core:
                return NSLocalizedString("Core", comment: "Section header for core properties of a service")
            case .data:
                return NSLocalizedString("Data", comment: "Section header for data associated with a service")
            }
        })

    required init(serviceController: ServiceController, service: Service) {
        self.serviceController = serviceController
        self.service = service
        super.init(nibName: nil, bundle: nil)
        build()
    }

    func build() {
        title = service.typeWithDomain
        var snapshot = NSDiffableDataSourceSnapshot<Section, Row>()
        snapshot.appendSections([.core])

        snapshot.appendItems([
            Row(name: NSLocalizedString("Name", comment: "Label for the name of the service"), value: service.name),
            Row(name: NSLocalizedString("Type", comment: "Label for the type of the service (eg _http._tcp)"), value: service.type)
        ])

        if let domain = service.domain {
            snapshot.appendItems([
                Row(name: NSLocalizedString("Domain", comment: "Label for the domain of the service (when not local)"), value: domain)
            ])
        }

        snapshot.appendItems(service.addressCluster.sorted.map { address in
            Row(name: NSLocalizedString("Address", comment: "Label for the network address of the service"), value: address)
        })

        snapshot.appendItems([
            Row(name: NSLocalizedString("Port", comment: "Label for the network port of the service"), value: String(service.port))
        ])

        if !service.data.isEmpty {
            let sortedData = service.data.sorted { $0.key.lowercased() < $1.key.lowercased() }
            snapshot.appendSections([.data])
            snapshot.appendItems(sortedData.map { Row(name: $0.key, value: $0.value) })
        }

        dataSource.apply(snapshot, animatingDifferences: collectionView.window != nil)
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
            .map { [service] hosts in
                return hosts.serviceMatching(service: service)
            }
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(on: MainScheduler.instance)
            .subscribe { [weak self] service in
                self?.serviceChanged(to: service)
            }
            .disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        for selected in collectionView.indexPathsForSelectedItems ?? [] {
            collectionView.deselectItem(at: selected, animated: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return urlFor(indexPath: indexPath) != nil
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let url = urlFor(indexPath: indexPath) {
            AppDelegate.instance.openUrl(url, from: self)
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    func collectionView(_: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
        guard let row = dataSource.itemIdentifier(for: indexPath) else { return nil }
        guard let section = dataSource.sectionIdentifier(for: indexPath.section) else { return nil }
        let url = urlFor(indexPath: indexPath)

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return nil }

            var actions = section == .core ? [
                UIAction(title: "Copy Value", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                    UIPasteboard.general.string = row.value
                },
            ] : [
                UIAction(title: "Copy Name", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                    UIPasteboard.general.string = row.name
                },
                UIAction(title: "Copy Value", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                    UIPasteboard.general.string = row.value
                },
            ]

            if let url = url {
                actions.append(UIAction(title: "Open", image: UIImage(systemName: "arrowshape.turn.up.right")) { [weak self] _ in
                    guard let self = self else { return }
                    AppDelegate.instance.openUrl(url, from: self)
                })
            }

            return UIMenu(title: "", children: actions)
        }
    }

    func urlFor(indexPath: IndexPath) -> URL? {
        guard let row = dataSource.itemIdentifier(for: indexPath) else { return nil }
        return urlFor(item: row)
    }

    func urlFor(item: Row) -> URL? {
        if item.value == service.type {
            return service.url
        }
        // return the value if it looks like it parses as a decent url
        if let url = URL(string: item.value), url.scheme != nil, url.host != nil {
            return url
        }
        return nil
    }

    func serviceChanged(to service: Service?) {
        if let found = service {
            self.service = found
            alive = found.alive
        } else {
            // this service is gone. Keep the addresses in case it comes back.
            alive = false
        }
        build()
    }
}
