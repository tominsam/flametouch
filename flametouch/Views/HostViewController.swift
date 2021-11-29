// Copyright 2016 Thomas Insam. All rights reserved.

import UIKit

/// View of a single host - lists the services of that host
class HostViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let serviceController: ServiceController
    var serviceControllerObserver: ServiceControllerObserver?

    var host: Host
    var alive: Bool

    lazy var tableView = configure(UITableView(frame: CGRect.zero, style: .insetGrouped)) { tableView in
        tableView.dataSource = self
        tableView.delegate = self
        tableView.setupForAutolayout()
        tableView.registerReusableCell(SimpleCell.self)
    }

    required init(serviceController: ServiceController, host: Host) {
        self.serviceController = serviceController
        self.host = host
        self.alive = true
        super.init(nibName: nil, bundle: nil)
        title = host.name

        serviceControllerObserver = serviceController.observeServiceChanges { [weak self] _ in
            self?.hostsChanged()
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        view.addSubview(tableView)
        tableView.pinEdgesTo(view: view)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: true)
        }
    }

    func hostsChanged() {
        if let found = serviceController.hostFor(addresses: host.addresses) {
            host = found
            alive = true
        } else {
            // this service is gone. Keep the addresses in case it comes back.
            alive = false
        }
        title = host.name
        tableView.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return host.displayAddresses.count
        } else {
            return host.services.count
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return host.displayAddresses.count > 1 ? "Addresses" : "Address"
        } else {
            return "Services"
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell: SimpleCell = tableView.dequeueReusableCell(for: indexPath)
            cell.title = host.displayAddresses[indexPath.row]
            cell.subtitle = nil
            cell.accessoryType = .none
            cell.selectionStyle = .none
            cell.contentView.alpha = alive ? 1 : 0.5
            return cell
        } else {
            let cell: SimpleCell = tableView.dequeueReusableCell(for: indexPath)
            let service = host.displayServices[indexPath.row]
            cell.title = service.name
            cell.subtitle = service.type
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            cell.contentView.alpha = alive ? 1 : 0.5
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            let service = host.displayServices[indexPath.row]
            let serviceController = ServiceViewController(serviceController: serviceController, service: service)
            show(serviceController, sender: self)
        }
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {

        if indexPath.section == 0 { // Hostname + Address rows
            // capture asap in case the tableview moves under us
            let value = host.displayAddresses[indexPath.row]
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                let copyValueAction = UIAction(title: "Copy Value", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                    UIPasteboard.general.string = value
                }
                return UIMenu(title: "", children: [copyValueAction])
            }

        } else { // Service rows

            let service = host.displayServices[indexPath.row]

            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                var actions = [UIAction]()
                actions.append(UIAction(title: "Copy Name", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                    UIPasteboard.general.string = service.name
                })
                actions.append(UIAction(title: "Copy Type", image: UIImage(systemName: "arrowshape.turn.up.right")) { _ in
                    UIPasteboard.general.string = service.type
                })
                if let url = service.url {
                    actions.append(UIAction(title: "Open", image: UIImage(systemName: "arrowshape.turn.up.right")) { [weak self] _ in
                        guard let self = self else { return }
                        AppDelegate.instance().openUrl(url, from: self)
                    })
                }

                return UIMenu(title: "", children: actions)
            }
        }
    }

}
