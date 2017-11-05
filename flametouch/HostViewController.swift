//
//  Host.swift
//  flametouch
//
//  Created by tominsam on 2/21/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import UIKit
import Crashlytics

class HostViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerPreviewingDelegate {

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

    override func loadView() {
        Answers.logContentView(withName: "host", contentType: "screen", contentId: nil, customAttributes: [
            "services": serviceGroup?.services.count ?? 0
        ])

        view = UIView(frame: CGRect.null)

        navigationController?.navigationBar.prefersLargeTitles = true

        table.dataSource = self
        table.delegate = self
        table.estimatedRowHeight = 100
        table.register(UINib(nibName: "HostCell", bundle: Bundle.main), forCellReuseIdentifier: "HostCell")
        table.register(AddressCell.self, forCellReuseIdentifier: "AddressCell")

        view.addSubview(table)
        table.pinEdgesTo(view: view)

        registerForPreviewing(with: self, sourceView: table)
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell") as! AddressCell?
            if (indexPath.row == 0) {
                cell!.textLabel!.text = serviceGroup!.services[0].hostName
            } else {
                cell!.textLabel!.text = addresses[indexPath.row - 1]
            }
            return cell!
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HostCell") as! HostCell?
            let service = serviceGroup!.services[indexPath.row]
            cell!.title!.text = service.name
            cell!.subTitle!.text = service.type
            return cell!
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if (indexPath.section == 0) {
            
        } else {
            let service = serviceGroup!.services[indexPath.row]
            let serviceController = DetailViewController(service: service)
            navigationController?.pushViewController(serviceController, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return action == #selector(UIResponderStandardEditActions.copy)
    }
    
    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                UIPasteboard.general.string = serviceGroup!.services[0].hostName
            } else {
                UIPasteboard.general.string = addresses[indexPath.row - 1]
            }
        } else {
            if let hasGroup = serviceGroup {
                UIPasteboard.general.string = hasGroup.services[indexPath.row].name
            }
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = table.indexPathForRow(at: location) {
            if (indexPath.section == 0) {
                return nil
            } else {
                let service = serviceGroup!.services[indexPath.row]
                let serviceController = DetailViewController(service: service)
                return serviceController
            }

        }
        return nil
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit vc: UIViewController) {
        navigationController?.pushViewController(vc, animated: false)
    }

}

