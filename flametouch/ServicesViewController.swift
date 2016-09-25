//
//  ServicesViewController.swift
//  flametouch
//
//  Created by tominsam on 10/10/15.
//  Copyright © 2015 tominsam. All rights reserved.
//

import UIKit
import PureLayout

class ServicesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerPreviewingDelegate {

    let table = UITableView(frame: CGRect.zero, style: .grouped)
    let networkOverlay = UIView(frame: CGRect.zero)
    let titleView = UILabel()
    let subtitleView = UILabel()
    
    let wirelessDetect = WirelessDetect()
    
    override func loadView() {
        self.view = UIView(frame: CGRect.null)
        self.view.addSubview(table)
        self.view.addSubview(networkOverlay)
        
        table.dataSource = self
        table.delegate = self
        
        table.autoPinEdgesToSuperviewEdges()
        table.estimatedRowHeight = 100
        table.register(UINib(nibName: "HostCell", bundle: Bundle.main), forCellReuseIdentifier: "HostCell")
        table.estimatedRowHeight = 100
        table.register(UINib(nibName: "HostCell", bundle: Bundle.main), forCellReuseIdentifier: "HostCell")

        networkOverlay.autoPinEdgesToSuperviewEdges()
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

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "About", style: .plain, target: self, action: #selector(aboutPressed))
        
        registerForPreviewing(with: self, sourceView: self.table)
        
        networkOverlay.isHidden = wirelessDetect.hasWireless()
        wirelessDetect.callback = { (wifi:Bool) -> Void in
            self.networkOverlay.isHidden = wifi
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(servicesChanged),
            name: NSNotification.Name(rawValue: "ServicesChanged"),
            object: nil)
    }
    
    func aboutPressed() {
//        navigationController?.presentViewController(AboutViewController(), animated: true, completion: nil)
        navigationController?.pushViewController(AboutViewController(), animated: true)
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

