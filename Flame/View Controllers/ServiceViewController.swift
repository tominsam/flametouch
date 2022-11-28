// Copyright 2016 Thomas Insam. All rights reserved.

import RxSwift
import ServiceDiscovery
import UIKit
import Utils
import Views

/// Shows the details of a particular service on a particular host
class ServiceViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let serviceController: ServiceController
    let disposeBag = DisposeBag()

    var service: Service
    var core = [(key: String, value: String)]()
    var txtData = [(key: String, value: String)]()
    var alive = true

    lazy var tableView = with(UITableView(frame: .zero, style: .insetGrouped)) { tableView in
        tableView.dataSource = self
        tableView.delegate = self
        tableView.setupForAutolayout()
        tableView.registerReusableCell(SimpleCell.self)
        tableView.selectionFollowsFocus = true
    }

    required init(serviceController: ServiceController, service: Service) {
        self.serviceController = serviceController
        self.service = service
        super.init(nibName: nil, bundle: nil)
        build()
    }

    func build() {
        title = service.typeWithDomain

        core.removeAll()
        core.append((
            key: NSLocalizedString("Name", comment: "Label for the name of the service"),
            value: service.name
        ))
        core.append((
            key: NSLocalizedString("Type", comment: "Label for the type of the service (eg _http._tcp)"),
            value: service.type
        ))
        if let domain = service.domain {
            core.append((
                key: NSLocalizedString("Domain", comment: "Label for the domain of the service (when not local)"),
                value: domain
            ))
        }
        for hostname in service.displayAddresses {
            core.append((
                key: NSLocalizedString("Address", comment: "Label for the network address of the service"),
                value: hostname
            ))
        }
        core.append((
            key: NSLocalizedString("Port", comment: "Label for the network port of the service"),
            value: String(service.port)
        ))

        txtData = service.data.sorted { $0.key.lowercased() < $1.key.lowercased() }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        view.addSubview(tableView)
        tableView.pinEdgesTo(view: view)
        serviceController.services.subscribe { [weak self] hosts in
            self?.hostsChanged(hosts: hosts)
        }.disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: true)
        }
    }

    func numberOfSections(in _: UITableView) -> Int {
        if txtData.isEmpty {
            return 1
        } else {
            return 2
        }
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return NSLocalizedString("Core", comment: "Header label for a list of core service settings")
        case 1:
            return NSLocalizedString("Data", comment: "Header label for a list of service information from the data record")
        default:
            return nil
        }
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return core.count
        case 1:
            return txtData.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: SimpleCell = tableView.dequeueReusableCell(for: indexPath)

        switch indexPath.section {
        case 0:
            cell.title = core[indexPath.row].key
            cell.right = core[indexPath.row].value
        case 1:
            cell.title = txtData[indexPath.row].key
            cell.right = txtData[indexPath.row].value
        default:
            break
        }

        if urlFor(indexPath: indexPath) != nil {
            // cell can be selected
            cell.selectionStyle = .default
            cell.rightView.textColor = .systemRed // can't use tintcolor as we're not attached to the table yet
        } else {
            cell.selectionStyle = .none
            cell.rightView.textColor = .secondaryLabel
        }

        cell.contentView.alpha = alive ? 1 : 0.3
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let url = urlFor(indexPath: indexPath) {
            AppDelegate.instance.openUrl(url, from: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
        // capture asap in case the tableview moves under us
        if indexPath.section == 0 {
            let row = core[indexPath.row]
            let url = urlFor(indexPath: indexPath)

            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
                guard let self = self else { return nil }

                var actions = [
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
        } else {
            let row = txtData[indexPath.row]
            let url = urlFor(indexPath: indexPath)

            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
                guard let self = self else { return nil }

                var actions = [
                    UIAction(title: "Copy Name", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                        UIPasteboard.general.string = row.key
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
    }

    func urlFor(indexPath: IndexPath) -> URL? {
        switch indexPath.section {
        case 0:
            if core[indexPath.row].value == service.type {
                return service.url
            }
        case 1:
            // return the value if it looks like it parses as a decent url
            if let url = URL(string: txtData[indexPath.row].value), url.scheme != nil, url.host != nil {
                return url
            }
        default:
            break
        }
        return nil
    }

    func hostsChanged(hosts: [Host]) {
        if let found = hosts.matching(addresses: service.addresses)?.services.matching(service: service) {
            service = found
            alive = true
        } else {
            // this service is gone. Keep the addresses in case it comes back.
            alive = false
        }
        build()
        tableView.reloadData()
    }
}