//
//  Host.swift
//  flametouch
//
//  Created by tominsam on 2/21/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import UIKit
import PureLayout

class HostViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerPreviewingDelegate {

    let table = UITableView(frame: CGRect.zero, style: .grouped)
    var serviceGroup : ServiceGroup?
    var addresses : [String]

    required init(serviceGroup : ServiceGroup) {
        self.serviceGroup = serviceGroup
        addresses = serviceGroup.addresses
        super.init(nibName: nil, bundle: nil)
        title = serviceGroup.title
        //NSLog("serviceGroup is %@", serviceGroup)

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
        view = UIView(frame: CGRect.null)

        table.dataSource = self
        table.delegate = self
        table.estimatedRowHeight = 100
        table.register(UINib(nibName: "HostCell", bundle: Bundle.main), forCellReuseIdentifier: "HostCell")

        view.addSubview(table)
        table.autoPinEdgesToSuperviewEdges()

        registerForPreviewing(with: self, sourceView: table)
    }

    func browser() -> ServiceBrowser {
        return AppDelegate.instance().browser
    }

    func servicesChanged() {
        if let group = browser().serviceGroupFor(addresses) {
            serviceGroup = group
            addresses = group.addresses
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let group = serviceGroup {
            return group.services.count
        }
        return 0;
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return addresses.isEmpty ? "" : addresses.first
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HostCell") as! HostCell?

        let service = serviceGroup!.services[(indexPath as NSIndexPath).row]
        cell!.title!.text = service.name
        cell!.subTitle!.text = service.type
        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let service = serviceGroup!.services[(indexPath as NSIndexPath).row]
        let serviceController = DetailViewController(service: service)
        navigationController?.pushViewController(serviceController, animated: true)
        
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = table.indexPathForRow(at: location) {
            let service = serviceGroup!.services[(indexPath as NSIndexPath).row]
            let serviceController = DetailViewController(service: service)
            return serviceController
        }
        return nil
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit vc: UIViewController) {
        navigationController?.pushViewController(vc, animated: false)
    }

}

