// Copyright 2016 Thomas Insam. All rights reserved.

import RxSwift
import ServiceDiscovery
import UIKit
import Utils
import Views

/// View of a single host - lists the services of that host
class HostViewController: UIViewController, UITableViewDelegate {
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

    lazy var tableView = with(UITableView(frame: CGRect.zero, style: .insetGrouped)) { tableView in
        tableView.delegate = self
        tableView.setupForAutolayout()
        tableView.registerReusableCell(SimpleCell.self)
    }

    lazy var dataSource = HostDiffableDataSource(tableView: tableView) { tableView, indexPath, row in
        let cell: SimpleCell = tableView.dequeueReusableCell(for: indexPath)
        switch row {
        case .address(let address, let alive):
            cell.title = address
            cell.subtitle = nil
            cell.accessoryType = .none
            cell.selectionStyle = .none
            cell.contentView.alpha = alive ? 1 : 0.3
        case .service(let service):
            cell.title = service.name
            cell.subtitle = service.typeWithDomain
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            cell.contentView.alpha = service.alive ? 1 : 0.3
        }
        return cell
    }

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
        view.addSubview(tableView)
        tableView.pinEdgesTo(view: view)
        tableView.dataSource = dataSource

        serviceController.services
            .host(forAddressCluster: addressCluster)
            .throttle(.milliseconds(200), scheduler: MainScheduler.instance)
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] host in
                self?.updateHost(host)
            }
            .disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: true)
        }
    }

    func updateHost(_ host: Host) {
        self.title = host.name
        var snapshot = NSDiffableDataSourceSnapshot<Section, Row>()
        snapshot.appendSections([Section.addresses, .services])
        snapshot.appendItems(addressCluster.sorted.map { .address($0, host.alive) }, toSection: .addresses)
        snapshot.appendItems(host.displayServices.map { .service($0) }, toSection: .services)
        snapshot.reconfigureItems(snapshot.itemIdentifiers)
        dataSource.apply(snapshot, animatingDifferences: tableView.frame.width > 0)

        // This is handling a bug where the cell is binding to the old version of the service
        // - STR is remove a service from a device, and it's not becoming disabled unless you
        // manually cause a cell refresh by navigating out and in again.
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let row = dataSource.itemIdentifier(for: indexPath) else { return }
        switch row {
        case .address:
            tableView.deselectRow(at: indexPath, animated: true)
        case .service(let service):
            let serviceController = ServiceViewController(serviceController: serviceController, service: service)
            show(serviceController, sender: self)
        }
    }

    func tableView(_: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
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

class HostDiffableDataSource: UITableViewDiffableDataSource<HostViewController.Section, HostViewController.Row> {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let count = self.tableView(tableView, numberOfRowsInSection: section)
        switch self.sectionIdentifier(for: section) {
        case .addresses:
            return count > 1 ? "Addresses" : "Address"
        case .services:
            return count > 1 ? "Services" : "Service"
        case .none:
            return nil
        }
    }

}
