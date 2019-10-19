//
//  ServiceViewController.swift
//  flametouch
//
//  Created by tominsam on 2/18/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import UIKit
import SafariServices

/// Shows the details of a particular service on a particular host
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
        for hostname in service.addresses!.compactMap({getIFAddress($0)}) {
            self.core.append([NSLocalizedString("Address", comment: "Label for the network address of the service"), hostname])
        }
        self.core.append([NSLocalizedString("Port", comment: "Label for the network port of the service"), String(service.port)])

        if let txtRecord = service.txtRecordData() {
            for (key, value) in NetService.dictionary(fromTXTRecord: txtRecord) {
                self.txtData.append([key, String(bytes: value, encoding: .utf8)!])
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        self.service = NetService() // dummy object
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        table.dataSource = self
        table.delegate = self
        table.setupForAutolayout()
        table.registerReusableCell(SimpleCell.self)
        self.view.addSubview(table)
        table.pinEdgesTo(view: view)
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
        let cell: SimpleCell = tableView.dequeueReusableCell(for: indexPath)

        switch (indexPath.section) {
        case 0:
            cell.title = core[indexPath.row][0]
            cell.right = core[indexPath.row][1]
            break
        case 1:
            cell.title = txtData[indexPath.row][0]
            cell.right = txtData[indexPath.row][1]
            break
        default:
            break
        }

        if canSelect(indexPath: indexPath) {
            cell.selectionStyle = .default
            cell.rightView.textColor = cell.tintColor
        } else {
            cell.selectionStyle = .none
            cell.rightView.textColor = .secondaryLabel
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        didSelect(indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return nil }

            let copyNameAction = UIAction(title: "Copy Name", image: UIImage(systemName: "doc.on.clipboard")) { [weak self] _ in
                guard let self = self else { return }
                if (indexPath.section == 0) {
                    UIPasteboard.general.string = self.core[indexPath.row][0]
                } else {
                    UIPasteboard.general.string = self.txtData[indexPath.row][0]
                }
            }

            let copyValueAction = UIAction(title: "Copy Value", image: UIImage(systemName: "doc.on.clipboard")) { [weak self] _ in
                guard let self = self else { return }
                if (indexPath.section == 0) {
                    UIPasteboard.general.string = self.core[indexPath.row][1]
                } else {
                    UIPasteboard.general.string = self.txtData[indexPath.row][1]
                }
            }
            var actions = [copyNameAction, copyValueAction]

            if self.canSelect(indexPath: indexPath) {
                actions.append(UIAction(title: "Open", image: UIImage(systemName: "arrowshape.turn.up.right")) { [weak self] _ in
                    guard let self = self else { return }
                    self.didSelect(indexPath: indexPath)
                })
            }

            return UIMenu(title: "", children: actions)
        }
    }

    func canSelect(indexPath: IndexPath) -> Bool {
        return urlFor(indexPath: indexPath) != nil
    }

    func didSelect(indexPath: IndexPath) {
        if let url = urlFor(indexPath: indexPath), let scheme = url.scheme {
            switch scheme {
            case "http", "https":
                // If there's a universal link handler for this URL, use that for preference
                UIApplication.shared.open(url, options: [.universalLinksOnly: true]) { result in
                    if !result {
                        let vc = SFSafariViewController(url: url)
                        self.present(vc, animated: true)
                    }
                }
            default:
                UIApplication.shared.open(url, options: [:]) { result in
                    if !result {
                        let alertController = UIAlertController(title: "Can't open URL", message: "I couldn't open that URL - maybe you need a particular app installed", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alertController, animated: true)
                    }
                }
            }
        }
    }

    func urlFor(indexPath: IndexPath) -> URL? {
        switch (indexPath.section) {
        case 0:
            switch core[indexPath.row][1].split(separator: ".").first {
            case "_http":
                return URL(string: "http://\(service.hostName!):\(service.port)/")
            case "_https":
                return URL(string: "https://\(service.hostName!):\(service.port)/")
            case "_ssh":
                return URL(string: "ssh://\(service.hostName!):\(service.port)/")
            case "_smb":
                return URL(string: "smb://\(service.hostName!):\(service.port)/")
            default:
                return nil
            }
        case 1:
            // return the value if it looks like it parses as a decent url
            if let url = URL(string: txtData[indexPath.row][1]), url.scheme != nil, url.host != nil {
                return url
            }
        default:
            break
        }
        return nil
    }

}

