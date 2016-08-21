//
//  Host.swift
//  flametouch
//
//  Created by tominsam on 2/21/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import UIKit
import PureLayout

class HostViewController: StateViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerPreviewingDelegate {

    let table = UITableView(frame: CGRect.zero, style: .grouped)
    let serviceGroup : ServiceGroup

    required init(serviceGroup : ServiceGroup) {
        self.serviceGroup = serviceGroup
        super.init(nibName: nil, bundle: nil)
        self.title = serviceGroup.title
        NSLog("serviceGroup is %@", serviceGroup)
    }

    required init?(coder aDecoder: NSCoder) {
        self.serviceGroup = ServiceGroup(service: NetService(), address: "")
        super.init(coder: aDecoder)
    }


    override func loadView() {
        self.view = UIView(frame: CGRect.null)

        table.dataSource = self
        table.delegate = self
        table.estimatedRowHeight = 100
        table.register(UINib(nibName: "HostCell", bundle: Bundle.main), forCellReuseIdentifier: "HostCell")

        self.view.addSubview(table)
        table.autoPinEdgesToSuperviewEdges()

        NotificationCenter.default.addObserver(self, selector: #selector(servicesChanged), name: NSNotification.Name(rawValue: "ServicesChanged"), object: nil)
        registerForPreviewing(with: self, sourceView: self.table)
    }

    func servicesChanged() {
        table.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return serviceGroup.services.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return serviceGroup.address
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HostCell") as! HostCell?

        let service = serviceGroup.services[(indexPath as NSIndexPath).row]
        cell!.title!.text = service.name
        cell!.subTitle!.text = service.type
        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let service = serviceGroup.services[(indexPath as NSIndexPath).row]
        let serviceController = DetailViewController(service: service)
        navigationController?.pushViewController(serviceController, animated: true)
        
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = table.indexPathForRow(at: location) {
            let service = serviceGroup.services[(indexPath as NSIndexPath).row]
            let serviceController = DetailViewController(service: service)
            return serviceController
        }
        return nil
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit vc: UIViewController) {
        navigationController?.pushViewController(vc, animated: false)
    }

}

