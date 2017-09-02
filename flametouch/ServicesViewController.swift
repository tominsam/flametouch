//
//  ServicesViewController.swift
//  flametouch
//
//  Created by tominsam on 10/10/15.
//  Copyright © 2015 tominsam. All rights reserved.
//

import UIKit
import Crashlytics

class ServicesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerPreviewingDelegate {

    let table = UITableView(frame: CGRect.zero, style: .grouped)
    let networkOverlay = UIView(frame: CGRect.zero)
    let titleView = UILabel()
    let subtitleView = UILabel()
    
    let wirelessDetect = WirelessDetect()
    
    override func loadView() {
        Answers.logContentView(withName: "services", contentType: "screen", contentId: nil, customAttributes: nil)
        
        self.view = UIView(frame: CGRect.null)
        self.view.addSubview(table)
        self.view.addSubview(networkOverlay)
        
        table.dataSource = self
        table.delegate = self
        
        table.pinEdgesTo(view: view)
        table.estimatedRowHeight = 100
        table.register(UINib(nibName: "HostCell", bundle: Bundle.main), forCellReuseIdentifier: "HostCell")
        table.estimatedRowHeight = 100
        table.register(UINib(nibName: "HostCell", bundle: Bundle.main), forCellReuseIdentifier: "HostCell")

        networkOverlay.pinEdgesTo(view: view)
        networkOverlay.backgroundColor = UIColor.white
        networkOverlay.addSubview(titleView)
        let guide = networkOverlay.readableContentGuide

        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 180).isActive = true
        titleView.leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true
        titleView.trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true

        titleView.font = UIFont.preferredFont(forTextStyle: .title1)
        titleView.textAlignment = .center
        titleView.numberOfLines = 0
        titleView.text = "No wireless network found".widont()

        networkOverlay.addSubview(subtitleView)
        subtitleView.translatesAutoresizingMaskIntoConstraints = false
        subtitleView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 40).isActive = true
        subtitleView.leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true
        subtitleView.trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true
        subtitleView.textAlignment = .center
        subtitleView.numberOfLines = 0
        subtitleView.font = UIFont.preferredFont(forTextStyle: .title2)
        subtitleView.text = "Connect to a WiFi network to see local services.".widont()

        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIButton(type: .infoLight).image(for: .normal), style: .plain, target: self, action: #selector(aboutPressed))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Export"), style: .plain, target: self, action: #selector(exportData))
        
        registerForPreviewing(with: self, sourceView: self.table)
        
        networkOverlay.isHidden = true // wirelessDetect.hasWireless()
        wirelessDetect.callback = { (wifi:Bool) -> Void in
            let nowifi = !wifi
            let noservices = self.browser().serviceGroups.isEmpty
            let showOverlay = nowifi && noservices
            self.networkOverlay.isHidden = !showOverlay
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(servicesChanged),
            name: NSNotification.Name(rawValue: "ServicesChanged"),
            object: nil)
    }
    
    @objc
    func aboutPressed() {
        navigationController?.pushViewController(AboutViewController(), animated: true)
    }
    
    @objc
    func exportData() {

        var groupsJson : [Any] = []
        var host_count = 0
        var service_count = 0
        for serviceGroup in browser().serviceGroups {
            host_count += 1
            var groupJson : [String:Any] = [:]
            groupJson["name"] = serviceGroup.title
            var addressesJson : [String] = []
            for address in serviceGroup.addresses {
                addressesJson.append(address)
            }
            groupJson["addresses"] = addressesJson
            
            var servicesJson : [Any] = []
            for service in serviceGroup.services {
                service_count += 1
                var serviceJson : [String: Any] = [:]
                serviceJson["name"] = service.name
                serviceJson["port"] = service.port
                serviceJson["type"] = service.type
                var addressesJson : [String] = []
                let addresses = service.addresses!.flatMap { getIFAddress($0) }
                for address in addresses {
                    addressesJson.append(address)
                }
                serviceJson["addresses"] = addressesJson
                if let txtRecord = service.txtRecordData() {
                    for (key, value) in NetService.dictionary(fromTXTRecord: txtRecord) {
                        serviceJson[key] = String(bytes: value, encoding: .utf8)
                    }
                }

                servicesJson.append(serviceJson)
            }
            groupJson["services"] = servicesJson
            
            groupsJson.append(groupJson)
        }

        Answers.logCustomEvent(withName: "export", customAttributes: [
            "services": service_count,
            "hosts": host_count])

        let file = "services_export.json"
        
        if let dir = NSSearchPathForDirectoriesInDomains(
                FileManager.SearchPathDirectory.documentDirectory,
                FileManager.SearchPathDomainMask.allDomainsMask,
                true
            ).first,
            let path = NSURL(fileURLWithPath: dir).appendingPathComponent(file)
        {
            NSLog("path is \(path.path)")
            let output = OutputStream(toFileAtPath: path.path, append: false)!
            output.open()
            JSONSerialization.writeJSONObject(groupsJson, to: output, options: JSONSerialization.WritingOptions.prettyPrinted, error: nil)
            output.close()

            // show system share dialog for this file
            let controller = UIActivityViewController(activityItems: [path], applicationActivities: nil)
            // on iPad, we attach the share sheet to the button that activated it
            controller.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            present(controller, animated: true, completion: nil)
        }

    }
    
    @objc func servicesChanged() {
        table.reloadData()
        if !browser().serviceGroups.isEmpty {
            self.networkOverlay.isHidden = true
        }
    }

    func browser() -> ServiceBrowser {
        return AppDelegate.instance().browser
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return browser().serviceGroups.count;
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HostCell") as! HostCell?

        let serviceGroup = getRow(indexPath)
        cell!.title!.text = serviceGroup.title
        cell!.subTitle!.text = serviceGroup.subTitle

        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = HostViewController(serviceGroup: getRow(indexPath))
        navigationController?.pushViewController(vc, animated: true)
        
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = table.indexPathForRow(at: location) {
            let vc = HostViewController(serviceGroup: getRow(indexPath))
            return vc
        }
        return nil
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit vc: UIViewController) {
        navigationController?.pushViewController(vc, animated: false)
    }

    func getRow(_ indexPath: IndexPath) -> ServiceGroup {
        return browser().serviceGroups[(indexPath as NSIndexPath).row]
    }


}

