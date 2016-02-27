//
//  ViewController.swift
//  flametouch
//
//  Created by tominsam on 10/10/15.
//  Copyright © 2015 tominsam. All rights reserved.
//

import UIKit
import PureLayout

private var myContext = 0

class ViewController: StateViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerPreviewingDelegate {

    let table = UITableView()

    override func loadView() {
        self.view = UIView(frame: CGRectNull)

        table.dataSource = self
        table.delegate = self

        self.view.addSubview(table)
        table.autoPinEdgesToSuperviewEdges()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "servicesChanged", name: "ServicesChanged", object: nil)

        registerForPreviewingWithDelegate(self, sourceView: self.table)
	}

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NSLog("loaded")

    }

    func servicesChanged() {
        table.reloadData()
    }

    func browser() -> ServiceBrowser {
        return AppDelegate.instance().browser
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return browser().groups.count;
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("service")
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "service")
        }

        let ip = browser().groups.keys.sort()[indexPath.row]
        let services = browser().groups[ip]
        cell!.textLabel!.text = services?.first?.name
        cell!.detailTextLabel!.text = ip
        return cell!
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let ip = browser().groups.keys.sort()[indexPath.row]
        let vc = HostViewController(ip: ip)
        navigationController?.pushViewController(vc, animated: true)
        
    }

    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = table.indexPathForRowAtPoint(location) {
            let ip = browser().groups.keys.sort()[indexPath.row]
            let vc = HostViewController(ip: ip)
            return vc
        }
        return nil
    }

    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController vc: UIViewController) {
        navigationController?.pushViewController(vc, animated: false)
    }


}

