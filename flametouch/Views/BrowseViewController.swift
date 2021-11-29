// Copyright 2015 Thomas Insam. All rights reserved.

import UIKit

/// Root view of the app, renders a list of hosts on the local network
class BrowseViewController: UIViewController {

    let serviceController: ServiceController
    var serviceControllerObserver: ServiceControllerObserver?

    var filteredHosts = [Host]()
    var filter: String?

    lazy var tableView = configure(UITableView(frame: .zero, style: .insetGrouped)) { tableView in
        tableView.setupForAutolayout()
        #if !targetEnvironment(macCatalyst)
        tableView.refreshControl = configure(UIRefreshControl()) { refresh in
            refresh.addTarget(self, action: #selector(handleTableRefresh(sender:)), for: .valueChanged)
        }
        #endif
    }

    let networkOverlay = WifiView()

    lazy var searchController = configure(UISearchController()) {
        $0.delegate = self
        $0.searchResultsUpdater = self
        // Don't move the search bar over the navigation what searching
        $0.hidesNavigationBarDuringPresentation = false
        // don't dim when searching
        $0.obscuresBackgroundDuringPresentation = false
        // align with the insetgrouped bubbles
        $0.searchBar.layoutMargins = tableView.layoutMargins
        // don't draw background or borders behind bubbles - fits in with table better
        $0.searchBar.searchBarStyle = .default
        // Both background setters are needed to keep the right color
        // but also have the bar be opaque when focussed.
        $0.searchBar.backgroundColor = .systemGroupedBackground
        $0.searchBar.backgroundImage = UIImage()
        // Match search bar background and corner radius to the cells
        $0.searchBar.searchTextField.backgroundColor = .secondarySystemGroupedBackground
        $0.searchBar.searchTextField.layer.cornerRadius = 10
        $0.searchBar.searchTextField.layer.masksToBounds = true
        // Align icon to the contents of the cells
        $0.searchBar.setPositionAdjustment(UIOffset(horizontal: 6, vertical: 0), for: .search)
        $0.searchBar.searchTextPositionAdjustment = UIOffset(horizontal: 2, vertical: 0)
    }

    let wirelessDetect = WirelessDetect()

    init(serviceController: ServiceController) {
        self.serviceController = serviceController
        super.init(nibName: nil, bundle: nil)
        serviceControllerObserver = serviceController.observeServiceChanges { [weak self] _ in
            self?.hostsChanged()
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        #if targetEnvironment(macCatalyst)
        title = NSLocalizedString("Hosts", comment: "Title for a list of hosts (computers on the network)")
        #else
        title = NSLocalizedString("Flame", comment: "The name of the application")
        #endif

        // This causes the search controller to treat _this_ view as the "presentation context"
        // The effective upshot of this is that the search bar is pushed off screen on iPhone when
        // we tap a row, rather than staying attached to the split view controller.
        definesPresentationContext = true

        view.addSubviewWithInsets(tableView)
        view.addSubviewWithInsets(networkOverlay)

        tableView.tableHeaderView = searchController.searchBar
        tableView.dataSource = self
        tableView.delegate = self

        tableView.registerReusableCell(SimpleCell.self)

        // Suppress info button on mac because there's an about menu, but catalyst
        // does want an explicit refresh button.
        #if targetEnvironment(macCatalyst)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(handleTableRefresh(sender:)))
        #else
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIButton(type: .infoLight).image(for: .normal),
            style: .plain,
            target: self,
            action: #selector(aboutPressed))
        #endif

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "Export"),
            style: .plain,
            target: self,
            action: #selector(exportData))

        // Try to explain what's going on if there's no wifi. This
        // isn't currently very reliable.
        networkOverlay.isHidden = true
        wirelessDetect.callback = { [weak self] wifi in
            guard let self = self else { return }
            let nowifi = !wifi
            let noservices = self.serviceController.hosts.isEmpty
            let showOverlay = nowifi && noservices
            self.networkOverlay.isHidden = !showOverlay
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: true)
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
        guard let url = ServiceExporter.export(hosts: serviceController.hosts) else { return }
        // show system share dialog for this file
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        // on iPad, we attach the share sheet to the button that activated it
        controller.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(controller, animated: true, completion: nil)
    }

    func hostsChanged() {
        // preserve current selection if any
        let indexPath = tableView.indexPathForSelectedRow
        let oldHost = indexPath.map { filteredHosts[$0.row] }

        if let filter = self.filter {
            filteredHosts = serviceController.hosts.filter { $0.matches(filter) }
        } else {
            filteredHosts = serviceController.hosts
        }
        tableView.reloadData()
        if !serviceController.hosts.isEmpty {
            self.networkOverlay.isHidden = true
        }
        if let oldHost = oldHost {
            if let oldSelection = filteredHosts.firstIndex(where: { $0.hasAnyAddress(oldHost.addresses) }) {
                tableView.selectRow(at: IndexPath(row: oldSelection, section: 0), animated: false, scrollPosition: .none)
            }
        }
    }

    @objc func handleTableRefresh(sender: UIControl) {
        // Fake some delays on this because it looks unnatural if things
        // are instant. Refresh the list, then hide the spinner a second later.
        serviceController.restart()
        if let refresh = sender as? UIRefreshControl {
            // iOS devices have pull-to-refresh that we need to stop
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                refresh.endRefreshing()
            }
        }
        (splitViewController as? CustomSplitViewController)?.clearDetailViewController()
    }
}

extension BrowseViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredHosts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: SimpleCell = tableView.dequeueReusableCell(for: indexPath)
        let host = filteredHosts[indexPath.row]
        cell.title = host.name
        cell.subtitle = host.subtitle
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = HostViewController(serviceController: serviceController, host: filteredHosts[indexPath.row])
        show(vc, sender: self)
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        // capture asap in case the tableview moves under us
        let row = self.filteredHosts[indexPath.row]

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let copyNameAction = UIAction(title: "Copy Name", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                UIPasteboard.general.string = row.name
            }
            let copyAddressAction = UIAction(title: "Copy IP Address", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                UIPasteboard.general.string = row.address
            }
            return UIMenu(title: row.name, children: [copyNameAction, copyAddressAction])
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // returning any view at all here means there'll be space between the first cell
        // and the search bar.
        return UIView()
    }
}

extension BrowseViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        (splitViewController as? CustomSplitViewController)?.clearDetailViewController()
        if let searchText = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines), !searchText.isEmpty {
            filter = searchText
        } else {
            filter = nil
        }
        hostsChanged()
    }
}
