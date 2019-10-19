//
//  Host.swift
//  flametouch
//
//  Created by tominsam on 2/21/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import UIKit

/// View of a single host - lists the services of that host
class HostViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let table = UITableView(frame: CGRect.zero, style: .grouped)
    var serviceGroup : ServiceGroup?
    var addresses : [String]

    required init(serviceGroup : ServiceGroup) {
        self.serviceGroup = serviceGroup
        addresses = serviceGroup.addresses
        super.init(nibName: nil, bundle: nil)
        title = serviceGroup.title
        //ELog("serviceGroup is %@", serviceGroup)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(servicesChanged),
            name: NSNotification.Name(rawValue: "ServicesChanged"),
            object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        serviceGroup = ServiceGroup(service: NetService(), address: "")
        addresses = []
        super.init(coder: aDecoder)
        precondition(false) // don't want this happening
    }

    override func viewDidLoad() {
        table.dataSource = self
        table.delegate = self
        table.setupForAutolayout()
        table.registerReusableCell(SimpleCell.self)

        view.addSubview(table)
        table.pinEdgesTo(view: view)

    }

    func browser() -> ServiceBrowser {
        return AppDelegate.instance().browser
    }

    @objc func servicesChanged() {
        if let group = browser().serviceGroupFor(addresses) {
            serviceGroup = group
            addresses = group.addresses
            ELog("Addresses are \(addresses)")
        } else {
            // this service is gone. Keep the addresses in case it comes back.
            serviceGroup = nil
        }
        title = serviceGroup?.title
        table.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let group = serviceGroup {
            if (section == 0) {
                return addresses.count + 1
            } else {
                return group.services.count
            }
        }
        return 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            return addresses.count > 1 ? "Addresses" : "Address"
        } else {
            return "Services"
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.section == 0) {
            let cell: SimpleCell = tableView.dequeueReusableCell(for: indexPath)
            if (indexPath.row == 0) {
                cell.title = serviceGroup!.services[0].hostName
            } else {
                cell.title = addresses[indexPath.row - 1]
            }
            cell.accessoryType = .none
            return cell
        } else {
            let cell: SimpleCell = tableView.dequeueReusableCell(for: indexPath)
            let service = serviceGroup!.services[indexPath.row]
            cell.title = service.name
            cell.subtitle = service.type
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if (indexPath.section == 0) {
            
        } else {
            let service = serviceGroup!.services[indexPath.row]
            let serviceController = DetailViewController(service: service)
            show(serviceController, sender: self)
        }
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return nil }

            if indexPath.section == 0 {
                // Hostname + Address rows

                let copyValueAction = UIAction(title: "Copy Value", image: UIImage(systemName: "doc.on.clipboard")) { [weak self] _ in
                    guard let self = self else { return }
                    if (indexPath.row == 0) {
                        UIPasteboard.general.string = self.serviceGroup!.services[0].hostName
                    } else {
                        UIPasteboard.general.string = self.addresses[indexPath.row - 1]
                    }
                }

                return UIMenu(title: "", children: [copyValueAction])

            } else if let hasGroup = self.serviceGroup {
                // Services
                let copyNameAction = UIAction(title: "Copy Name", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                    UIPasteboard.general.string = hasGroup.services[indexPath.row].name
                }
                let copyTypeAction = UIAction(title: "Copy Type", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                    UIPasteboard.general.string = hasGroup.services[indexPath.row].type
                }

                return UIMenu(title: "", children: [copyNameAction, copyTypeAction])

            } else {
                return nil
            }
        }
    }


}

