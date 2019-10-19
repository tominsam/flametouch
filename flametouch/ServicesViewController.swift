//
//  ServicesViewController.swift
//  flametouch
//
//  Created by tominsam on 10/10/15.
//  Copyright © 2015 tominsam. All rights reserved.
//

import UIKit

/// Root view of the app, renders a list of hosts on the local network
class ServicesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let table = UITableView(frame: CGRect.zero, style: .grouped)
    let networkOverlay = UIView(frame: CGRect.zero)
    let titleView = UILabel()
    let subtitleView = UILabel()
    
    let wirelessDetect = WirelessDetect()
    
    override func viewDidLoad() {
        title = NSLocalizedString("Flame", comment: "App name")

        view.addSubview(table)
        view.addSubview(networkOverlay)
        
        table.dataSource = self
        table.delegate = self
        table.setupForAutolayout()

        table.pinEdgesTo(view: view)
        table.registerReusableCell(SimpleCell.self)

        networkOverlay.pinEdgesTo(view: view)
        networkOverlay.backgroundColor = .systemBackground
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

        navigationController?.navigationBar.prefersLargeTitles = false

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIButton(type: .infoLight).image(for: .normal), style: .plain, target: self, action: #selector(aboutPressed))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "Export"), style: .plain, target: self, action: #selector(exportData))
        
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let selected = table.indexPathForSelectedRow {
            table.deselectRow(at: selected, animated: true)
        }
    }

    @objc
    func aboutPressed() {
        #if targetEnvironment(macCatalyst)
        // About screen gets a dedicated window
        let userActivity = NSUserActivity(activityType: "org.jerakeen.flametouch.about")
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: userActivity, options: nil, errorHandler: nil)
        #else
        // About screen gets a modal
        let about = AboutViewController()
        about.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: about, action: #selector(AboutViewController.done))
        let vc = UINavigationController(rootViewController: about)
        vc.theme()
        present(vc, animated: true, completion: nil)
        #endif
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
                let addresses = service.addresses!.compactMap { getIFAddress($0) }
                for address in addresses {
                    addressesJson.append(address)
                }
                serviceJson["addresses"] = addressesJson
                if let txtRecord = service.txtRecordData() {
                    for (key, value) in NetService.dictionary(fromTXTRecord: txtRecord) {
                        serviceJson[key] = String(bytes: value, encoding: .utf8) ?? value.hex
                    }
                }

                servicesJson.append(serviceJson)
            }
            groupJson["services"] = servicesJson
            
            groupsJson.append(groupJson)
        }

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

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Hosts"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return browser().serviceGroups.count;
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:SimpleCell = tableView.dequeueReusableCell(for: indexPath)
        let serviceGroup = getRow(indexPath)
        cell.title = serviceGroup.title
        cell.subtitle = serviceGroup.subTitle
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = HostViewController(serviceGroup: getRow(indexPath))
        show(vc, sender: self)
    }

    func getRow(_ indexPath: IndexPath) -> ServiceGroup {
        return browser().serviceGroups[(indexPath as NSIndexPath).row]
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        // capture asap in case the tableview moves under us
        let row = self.getRow(indexPath)

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let copyNameAction = UIAction(title: "Copy Name", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                UIPasteboard.general.string = row.title
            }
            let copyAddressAction = UIAction(title: "Copy IP Address", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                UIPasteboard.general.string = row.address
            }
            return UIMenu(title: "", children: [copyNameAction, copyAddressAction])
        }
    }


}

