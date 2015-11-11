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

class ViewController: StateViewController, UITableViewDataSource, UITableViewDelegate {

    let table = UITableView()

    override func loadView() {
        self.view = UIView(frame: CGRectNull)

        table.dataSource = self
		table.delegate = self

        self.view.addSubview(table)
        table.autoPinEdgesToSuperviewEdges()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "servicesChanged", name: "ServicesChanged", object: nil)
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
        NSLog("got \(browser().services.count) services")
        return browser().services.count;
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        NSLog("got \(indexPath)")
        let service = browser().services[indexPath.row]
        let cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "cell")
        cell.textLabel!.text = service.name
        cell.detailTextLabel!.text = service.type
        return cell

    }


}

