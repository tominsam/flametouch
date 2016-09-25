//
//  ServiceViewController.swift
//  flametouch
//
//  Created by tominsam on 2/18/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let service : NetService
    let table = UITableView(frame: CGRect.zero, style: .grouped)

    var core = [[String]]()
    var txtData = [[String]]()

    required init(service : NetService) {
        self.service = service
        super.init(nibName: nil, bundle: nil)
        self.title = service.type
        self.core.append([NSLocalizedString("Name", comment: "Label for the name of the service"), service.name])
        self.core.append([NSLocalizedString("Type", comment: "Label for the type of the service"), service.type + service.domain])
        for hostname in service.addresses!.flatMap({getIFAddress($0)}) {
            self.core.append([NSLocalizedString("Address", comment: "Label for the network address of the service"), hostname])
        }
        self.core.append([NSLocalizedString("Port", comment: "Label for the network port of the service"), String(service.port)])

        for (key, value) in NetService.dictionary(fromTXTRecord: service.txtRecordData()!) {
            self.txtData.append([key, NSString(data: value, encoding: String.Encoding.utf8.rawValue) as! String])
        }
    }

    required init?(coder aDecoder: NSCoder) {
        self.service = NetService() // dummy object
        super.init(coder: aDecoder)
    }

    override func loadView() {
        self.view = UIView(frame: CGRect.null)

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


    func numberOfSections(in tableView: UITableView) -> Int {
        if txtData.isEmpty {
            return 1
        } else {
            return 2
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section) {
        case 0:
            return NSLocalizedString("Core", comment: "Header label for core service settings")
        case 1:
            return NSLocalizedString("Data", comment: "Header label for service settings from data record")
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0:
            return core.count
        case 1:
            return txtData.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "row")
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: "row")
        }

        switch (indexPath.section) {
        case 0:
            cell!.textLabel!.text = core[indexPath.row][0]
            let value = core[indexPath.row][1]
            cell!.detailTextLabel!.text = value
            if (value.hasPrefix("_http._tcp.")) {
                cell!.detailTextLabel!.textColor = self.view.window?.tintColor
            } else {
                cell!.detailTextLabel!.textColor = UIColor.gray
            }
            break
        case 1:
            let value = txtData[indexPath.row][1]
            cell!.textLabel!.text = txtData[indexPath.row][0]
            cell!.detailTextLabel!.text = value
            if (value.hasPrefix("http://") || value.hasPrefix("https://")) {
                cell!.detailTextLabel!.textColor = self.view.window?.tintColor
            } else {
                cell!.detailTextLabel!.textColor = UIColor.gray
            }
            break
        default:
            break
        }
        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch (indexPath.section) {
        case 0:
            if (core[indexPath.row][1].hasPrefix("_http._tcp.")) {
                let stringUrl = "http://\(self.service.hostName!):\(self.service.port)/"
                NSLog("stringurl is \(stringUrl)")
                if let url = URL(string: stringUrl) {
                    UIApplication.shared.openURL(url)
                }
            }
            break
        case 1:
            if let url = URL(string: txtData[indexPath.row][1]) {
                UIApplication.shared.openURL(url)
            }
            break
        default:
            break
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
            UIPasteboard.general.string = core[indexPath.row][1]
        } else {
            UIPasteboard.general.string = txtData[indexPath.row][1]
        }
    }

}
