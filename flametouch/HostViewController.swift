//
//  Host.swift
//  flametouch
//
//  Created by tominsam on 2/21/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import UIKit
import PureLayout

class HostViewController: StateViewController, UITableViewDataSource, UITableViewDelegate {

    let table = UITableView()
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

        self.view.addSubview(table)
        table.autoPinEdgesToSuperviewEdges()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "servicesChanged", name: "ServicesChanged", object: nil)
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
        var cell = tableView.dequeueReusableCellWithIdentifier("service")
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "service")
        }

        let service = group()[indexPath.row]
        cell!.textLabel!.text = service.name
        cell!.detailTextLabel!.text = service.type
        return cell!
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let service = group()[indexPath.row]
        let serviceController = ServiceViewController(service: service)
        navigationController?.pushViewController(serviceController, animated: true)
        
    }
    
    
}

