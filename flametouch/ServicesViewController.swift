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

    @IBOutlet var table : UITableView?
    @IBOutlet var networkOverlay : UIView?
    
    init() {
        super.init(nibName: "ServicesViewController", bundle: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(servicesChanged),
            name: NSNotification.Name(rawValue: "ServicesChanged"),
            object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        precondition(false) // don't want this happening
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        table!.estimatedRowHeight = 100
        table!.register(UINib(nibName: "HostCell", bundle: Bundle.main), forCellReuseIdentifier: "HostCell")
        
        registerForPreviewing(with: self, sourceView: self.table!)
        
        if WirelessDetect.hasWireless() {
            NSLog("i have wireless")
            networkOverlay?.isHidden = true
        } else {
            NSLog("no wireless")
            networkOverlay?.isHidden = false
        }
        networkOverlay?.isHidden = true
    }

    func aboutPressed() {
//        navigationController?.presentViewController(AboutViewController(), animated: true, completion: nil)
        navigationController?.pushViewController(AboutViewController(), animated: true)
    }

    func servicesChanged() {
        table?.reloadData()
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
        if let indexPath = table!.indexPathForRow(at: location) {
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

