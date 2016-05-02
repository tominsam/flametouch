//
//  ServiceViewController.swift
//  flametouch
//
//  Created by tominsam on 2/18/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let service : NSNetService
    let table = UITableView(frame: CGRectZero, style: .Grouped)

    var core = [[String]]()
    var txtData = [[String]]()

    required init(service : NSNetService) {
        self.service = service
        super.init(nibName: nil, bundle: nil)
        self.title = service.type
        self.core.append([NSLocalizedString("Name", comment: "Label for the name of the service"), service.name])
        self.core.append([NSLocalizedString("Type", comment: "Label for the type of the service"), service.type + service.domain])
        for hostname in service.addresses!.flatMap({getIFAddress($0)}) {
            self.core.append([NSLocalizedString("Address", comment: "Label for the network address of the service"), hostname])
        }
        self.core.append([NSLocalizedString("Port", comment: "Label for the network port of the service"), String(service.port)])

        for (key, value) in NSNetService.dictionaryFromTXTRecordData(service.TXTRecordData()!) {
            self.txtData.append([key, NSString(data: value, encoding: NSUTF8StringEncoding) as! String])
        }
    }

    required init?(coder aDecoder: NSCoder) {
        self.service = NSNetService() // dummy object
        super.init(coder: aDecoder)
    }

    override func loadView() {
        self.view = UIView(frame: CGRectNull)

        table.dataSource = self
        table.delegate = self
        table.allowsSelection = true

        self.view.addSubview(table)
        table.autoPinEdgesToSuperviewEdges()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if txtData.isEmpty {
            return 1
        } else {
            return 2
        }
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
        case 0:
            return NSLocalizedString("Core", comment: "Header label for core service settings")
        case 1:
            return NSLocalizedString("Data", comment: "Header label for service settings from data record")
        default:
            return nil
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0:
            return core.count
        case 1:
            return txtData.count
        default:
            return 0
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("row")
        if cell == nil {
            cell = UITableViewCell(style: .Value1, reuseIdentifier: "row")
        }

        switch (indexPath.section) {
        case 0:
            cell!.textLabel!.text = core[indexPath.row][0]
            let value = core[indexPath.row][1]
            cell!.detailTextLabel!.text = value
            if (value.hasPrefix("_http._tcp.")) {
                cell!.detailTextLabel!.textColor = self.view.window?.tintColor
            } else {
                cell!.detailTextLabel!.textColor = UIColor.grayColor()
            }
            break
        case 1:
            let value = txtData[indexPath.row][1]
            cell!.textLabel!.text = txtData[indexPath.row][0]
            cell!.detailTextLabel!.text = value
            if (value.hasPrefix("http://") || value.hasPrefix("https://")) {
                cell!.detailTextLabel!.textColor = self.view.window?.tintColor
            } else {
                cell!.detailTextLabel!.textColor = UIColor.grayColor()
            }
            break
        default:
            break
        }
        return cell!
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch (indexPath.section) {
        case 0:
            if (core[indexPath.row][1].hasPrefix("_http._tcp.")) {
                let stringUrl = "http://\(self.service.hostName!):\(self.service.port)/"
                NSLog("stringurl is \(stringUrl)")
                if let url = NSURL(string: stringUrl) {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
            break
        case 1:
            if let url = NSURL(string: txtData[indexPath.row][1]) {
                UIApplication.sharedApplication().openURL(url)
            }
            break
        default:
            break
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

    }

}
