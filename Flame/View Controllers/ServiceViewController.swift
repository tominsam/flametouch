// Copyright 2016 Thomas Insam. All rights reserved.

import RxSwift
import ServiceDiscovery
import UIKit
import Utils
import Views
import SnapKit

/// Shows the details of a particular service on a particular host
class ServiceViewController: UIViewController, UITableViewDelegate {
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

    lazy var tableView = with(UITableView(frame: .zero, style: .insetGrouped)) { tableView in
        tableView.delegate = self
        tableView.setupForAutolayout()
        tableView.registerReusableCell(SimpleCell.self)
        //tableView.selectionFollowsFocus = true
    }

    lazy var dataSource = ServiceDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, row in
        let cell: SimpleCell = tableView.dequeueReusableCell(for: indexPath)
        cell.title = row.name
        cell.right = row.value
        cell.contentView.alpha = self?.alive == true ? 1 : 0.3

        if self?.urlFor(indexPath: indexPath) != nil {
            // cell can be selected
            cell.selectionStyle = .default
            cell.rightView.textColor = AppDelegate.tintColor // can't use tintcolor as we're not attached to the table yet
        } else {
            cell.selectionStyle = .none
            cell.rightView.textColor = .secondaryLabel
        }

        return cell
    }

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
        ], toSection: .core)

        if let domain = service.domain {
            snapshot.appendItems([
                Row(name: NSLocalizedString("Domain", comment: "Label for the domain of the service (when not local)"), value: domain)
            ], toSection: .core)
        }

        snapshot.appendItems(service.addressCluster.sorted.map { address in
            Row(name: NSLocalizedString("Address", comment: "Label for the network address of the service"), value: address)
        })

        snapshot.appendItems([
            Row(name: NSLocalizedString("Port", comment: "Label for the network port of the service"), value: String(service.port))
        ])

        if !service.data.isEmpty {
            snapshot.appendSections([.data])
            snapshot.appendItems(service.data
                .sorted { $0.key.lowercased() < $1.key.lowercased() }
                .map { Row(name: $0.key, value: $0.value) },
                                 toSection: .data)
        }

        dataSource.apply(snapshot, animatingDifferences: tableView.window != nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
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
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let url = urlFor(indexPath: indexPath) {
            AppDelegate.instance.openUrl(url, from: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
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
        if row.value == service.type {
            return service.url
        }
        // return the value if it looks like it parses as a decent url
        if let url = URL(string: row.value), url.scheme != nil, url.host != nil {
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

class ServiceDiffableDataSource: UITableViewDiffableDataSource<ServiceViewController.Section, ServiceViewController.Row> {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch self.sectionIdentifier(for: section) {
        case .core:
            return "Core"
        case .data:
            return "Data"
        case .none:
            return nil
        }
    }

}
