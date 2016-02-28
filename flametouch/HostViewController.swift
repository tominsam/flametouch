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

    let table = UITableView(frame: CGRectZero, style: .Grouped)
    let ip : String

    required init(ip : String) {
        self.ip = ip
        super.init(nibName: nil, bundle: nil)
        self.title = group().first?.name
    }

    required init?(coder aDecoder: NSCoder) {
        self.ip = ""
        super.init(coder: aDecoder)
    }


    override func loadView() {
        self.view = UIView(frame: CGRectNull)

        table.dataSource = self
        table.delegate = self
        table.estimatedRowHeight = 100
        table.registerNib(UINib(nibName: "HostCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "HostCell")

        self.view.addSubview(table)
        table.autoPinEdgesToSuperviewEdges()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "servicesChanged", name: "ServicesChanged", object: nil)
        registerForPreviewingWithDelegate(self, sourceView: self.table)
    }

    func servicesChanged() {
        table.reloadData()
    }

    func browser() -> ServiceBrowser {
        return AppDelegate.instance().browser
    }

    func group() -> Array<NSNetService> {
        return browser().groups[self.ip] ?? []
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return group().count;
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("HostCell") as! HostCell?

        let service = group()[indexPath.row]
        cell!.title!.text = service.name
        cell!.subTitle!.text = service.type
        return cell!
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let service = group()[indexPath.row]
        let serviceController = ServiceViewController(service: service)
        navigationController?.pushViewController(serviceController, animated: true)
        
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = table.indexPathForRowAtPoint(location) {
            let service = group()[indexPath.row]
            let serviceController = ServiceViewController(service: service)
            return serviceController
        }
        return nil
    }

    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController vc: UIViewController) {
        navigationController?.pushViewController(vc, animated: false)
    }

}

