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
        for hostname in service.addresses!.compactMap({getIFAddress($0)}).sorted() {
            self.core.append([NSLocalizedString("Address", comment: "Label for the network address of the service"), hostname])
        }
        self.core.append([NSLocalizedString("Port", comment: "Label for the network port of the service"), String(service.port)])

        if let txtRecord = service.txtRecordData() {
            for (key, value) in NetService.dictionary(fromTXTRecord: txtRecord) {
                if let stringValue = String(bytes: value, encoding: .utf8) {
                    self.txtData.append([key, stringValue])
                } else {
                    self.txtData.append([key, value.hex])
                }
            }
        }

        // Sort by key
        self.txtData.sort { a, b in
            return a[0].lowercased() < b[0].lowercased()
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let selected = table.indexPathForSelectedRow {
            table.deselectRow(at: selected, animated: true)
        }
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

        if urlFor(indexPath: indexPath) != nil {
            // cell can be selected
            cell.selectionStyle = .default
            cell.rightView.textColor = cell.tintColor
        } else {
            cell.selectionStyle = .none
            cell.rightView.textColor = .secondaryLabel
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let url = urlFor(indexPath: indexPath) {
            didSelect(url: url)
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        // capture asap in case the tableview moves under us
        let row = indexPath.section == 0 ? self.core[indexPath.row] : self.txtData[indexPath.row]
        let url = self.urlFor(indexPath: indexPath)

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return nil }

            var actions = [
                UIAction(title: "Copy Name", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                    UIPasteboard.general.string = row[0]
                },
                UIAction(title: "Copy Value", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                    UIPasteboard.general.string = row[1]
                }
            ]

            if let url = url {
                actions.append(UIAction(title: "Open", image: UIImage(systemName: "arrowshape.turn.up.right")) { [weak self] _ in
                    guard let self = self else { return }
                    self.didSelect(url: url)
                })
            }

            return UIMenu(title: "", children: actions)
        }
    }

    func didSelect(url: URL?) {
        if let url = url, let scheme = url.scheme {
            switch scheme {
            case "http", "https":
                // If there's a universal link handler for this URL, use that for preference
                #if targetEnvironment(macCatalyst)
                let vc = SFSafariViewController(url: url)
                self.present(vc, animated: true)
                #else
                UIApplication.shared.open(url, options: [.universalLinksOnly: true]) { result in
                    if !result {
                        let vc = SFSafariViewController(url: url)
                        self.present(vc, animated: true)
                    }
                }
                #endif
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

extension Data {
    var hex: String {
        return self.map { b in String(format: "%02X", b) }.joined()
    }
}
