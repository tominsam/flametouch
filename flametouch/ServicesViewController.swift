//
//  ViewController.swift
//  flametouch
//
//  Created by tominsam on 10/10/15.
//  Copyright © 2015 tominsam. All rights reserved.
//

import UIKit
import PureLayout

class ServicesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIViewControllerPreviewingDelegate {

    let table = UITableView(frame: CGRect.zero, style: .grouped)

    override func loadView() {
        self.view = UIView(frame: CGRect.null)

        table.dataSource = self
        table.delegate = self

        self.view.addSubview(table)
        table.autoPinEdgesToSuperviewEdges()
        table.estimatedRowHeight = 100
        table.register(UINib(nibName: "HostCell", bundle: Bundle.main), forCellReuseIdentifier: "HostCell")

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "About", style: .plain, target: self, action: #selector(aboutPressed))

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(servicesChanged),
            name: NSNotification.Name(rawValue: "ServicesChanged"),
            object: nil)
        registerForPreviewing(with: self, sourceView: self.table)
	}

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NSLog("loaded")

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

