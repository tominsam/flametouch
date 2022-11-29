// Copyright 2015 Thomas Insam. All rights reserved.

import RxSwift
import ServiceDiscovery
import UIKit
import Utils
import Views
import RxCocoa

/// Root view of the app, renders a list of hosts on the local network
class BrowseViewController: UIViewController {
    let disposeBag = DisposeBag()

    let serviceController: ServiceController
    let searchTerm = PublishSubject<String?>()

    lazy var tableView = with(UITableView(frame: .zero, style: .insetGrouped)) { tableView in
        tableView.setupForAutolayout()

#if !targetEnvironment(macCatalyst)
        tableView.refreshControl = with(UIRefreshControl()) { refresh in
            refresh.addTarget(self, action: #selector(handleTableRefresh(sender:)), for: .valueChanged)
        }
#endif
    }

    lazy var dataSource = UITableViewDiffableDataSource<Int, AddressCluster>(tableView: tableView) { [weak self] tableView, indexPath, addressCluster in
        let cell: SimpleCell = tableView.dequeueReusableCell(for: indexPath)
        guard let host = self?.serviceController.host(for: addressCluster) else { return cell }
        cell.title = host.name
        cell.subtitle = host.subtitle
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.contentView.alpha = host.alive ? 1 : 0.3
        return cell
    }

    let networkOverlay = WifiView()

    lazy var searchController = with(UISearchController()) { searchController in
        // Don't move the search bar over the navigation what searching
        searchController.hidesNavigationBarDuringPresentation = false
        // don't dim when searching
        searchController.obscuresBackgroundDuringPresentation = false
        // align with the insetgrouped bubbles
        searchController.searchBar.layoutMargins = tableView.layoutMargins
        // don't draw background or borders behind bubbles - fits in with table better
        searchController.searchBar.searchBarStyle = .default
        // Both background setters are needed to keep the right color
        // but also have the bar be opaque when focussed.
        searchController.searchBar.backgroundColor = .systemGroupedBackground
        searchController.searchBar.backgroundImage = UIImage()
        // Match search bar background and corner radius to the cells
        searchController.searchBar.searchTextField.backgroundColor = .secondarySystemGroupedBackground
        searchController.searchBar.searchTextField.layer.cornerRadius = 10
        searchController.searchBar.searchTextField.layer.masksToBounds = true
        // Align icon to the contents of the cells
        searchController.searchBar.setPositionAdjustment(UIOffset(horizontal: 6, vertical: 0), for: .search)
        searchController.searchBar.searchTextPositionAdjustment = UIOffset(horizontal: 2, vertical: 0)

        searchController.searchBar.rx.text
            .trimmedOrNil
            .distinctUntilChanged()
            .subscribe(searchTerm)
            .disposed(by: disposeBag)
    }

    init(serviceController: ServiceController) {
        self.serviceController = serviceController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
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
        tableView.dataSource = dataSource
        tableView.delegate = self

        tableView.registerReusableCell(SimpleCell.self)

        // Suppress info button on mac because there's an about menu, but catalyst
        // does want an explicit refresh button.
#if targetEnvironment(macCatalyst)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(handleTableRefresh(sender:))
        )
#else
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIButton(type: .infoLight).image(for: .normal),
            style: .plain,
            target: self,
            action: #selector(aboutPressed)
        )
#endif

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(exportData)
        )

        // Watch network state and show information about needing wifi when
        // we're not on wifi and there are no services.
        networkOverlay.isHidden = true
        Observable
            .combineLatest(
                NetworkMonitor.shared.state,
                serviceController.services.map { $0.isEmpty }
            )
            .map { (state, noservices) in
                let nowifi = state.currentConnectionType != .wifi
                let showOverlay = nowifi && noservices
                return showOverlay
            }
            .observe(on: MainScheduler.instance)
            .subscribe { [weak self] showOverlay in
                self?.networkOverlay.isHidden = !showOverlay
            }
            .disposed(by: disposeBag)

        // Update the diffable datasource with the latest services, filtering by search term
        Observable
            .combineLatest(
                serviceController.services,
                searchTerm.startWith(nil)
            )
            .map { (hosts, searchTerm) in
                if let searchTerm {
                    return hosts.filter { $0.matches(search: searchTerm) }
                } else {
                    return hosts
                }
            }
            .observe(on: MainScheduler.instance)
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe { [weak self] hosts in
                self?.hostsChanged(to: hosts)
            }
            .disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: true)
        }
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [tableView]
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
        present(vc, animated: true, completion: nil)
#endif
    }

    @objc
    func exportData() {
        guard let hosts = try? serviceController.services.value() else { return }
        guard let url = ServiceExporter.export(hosts: hosts) else { return }
#if targetEnvironment(macCatalyst)
        let controller = UIDocumentPickerViewController(forExporting: [url])
#else
        // show system share dialog for this file
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        // on iPad, we attach the share sheet to the button that activated it
        controller.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
#endif
        present(controller, animated: true, completion: nil)
    }

    func hostsChanged(to hosts: [Host]) {
        // preserve current selection if any
        let oldAddressCluster: AddressCluster?
        if let indexPath = tableView.indexPathForSelectedRow {
            oldAddressCluster = dataSource.itemIdentifier(for: indexPath)
        } else {
            oldAddressCluster = nil
        }

        var focusedHost: IndexPath?
        if let focusedCell = tableView.visibleCells.first(where: { $0.isFocused }) {
            focusedHost = tableView.indexPath(for: focusedCell)
        }

        var snapshot = NSDiffableDataSourceSnapshot<Int, AddressCluster>()
        snapshot.appendSections([0])
        snapshot.appendItems(hosts.map { $0.addressCluster }, toSection: 0)
        // rebind _everything_, because hosts can change even if the address list did not
        snapshot.reconfigureItems(hosts.map { $0.addressCluster })
        let animated = tableView.window != nil && !snapshot.itemIdentifiers.isEmpty && !dataSource.snapshot().itemIdentifiers.isEmpty
        dataSource.apply(snapshot, animatingDifferences: animated)

        if let oldAddressCluster, let oldSelection = hosts.firstIndex(where: { $0.addressCluster == oldAddressCluster }) {
            tableView.selectRow(at: IndexPath(row: oldSelection, section: 0), animated: false, scrollPosition: .none)
        } else {
            (splitViewController as? CustomSplitViewController)?.clearSecondaryViewController()
        }
        if let focusedHost = focusedHost {
            // TODO:
            tableView.cellForRow(at: focusedHost)?.becomeFirstResponder()
        }
    }

    @objc func handleTableRefresh(sender: UIControl) {
        // Fake some delays on this because it looks unnatural if things
        // are instant. Refresh the list, then hide the spinner a second later.
        serviceController.restart()
        if let refresh = sender as? UIRefreshControl {
            // iOS devices have pull-to-refresh that we need to stop
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                refresh.endRefreshing()
            }
        }
    }
}

extension BrowseViewController: UITableViewDelegate {

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let addressCluster = dataSource.itemIdentifier(for: indexPath) else { return }
        let vc = HostViewController(serviceController: serviceController, addressCluster: addressCluster)
        show(vc, sender: self)
    }

    func tableView(_: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
        // capture asap in case the tableview moves under us
        guard let addressCluster = dataSource.itemIdentifier(for: indexPath) else { return nil }
        guard let host = serviceController.host(for: addressCluster) else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let copyNameAction = UIAction(title: "Copy Name", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                UIPasteboard.general.string = host.name
            }
            let copyAddressAction = UIAction(title: "Copy IP Address", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                UIPasteboard.general.string = host.addressCluster.displayAddress
            }
            return UIMenu(title: "", children: [copyNameAction, copyAddressAction])
        }
    }

    func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        // returning any view at all here means there'll be space between the first cell
        // and the search bar.
        return UIView()
    }
}

extension ObservableType where Element == String? {
    var trimmedOrNil: Observable<String?> {
        return self.map { (text: String?) -> String? in
            let t = text?.trimmingCharacters(in: .whitespacesAndNewlines)
            return t?.isEmpty == false ? t : nil
        }
    }
}
