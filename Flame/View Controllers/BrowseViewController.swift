// Copyright 2015 Thomas Insam. All rights reserved.

import RxSwift
import ServiceDiscovery
import UIKit
import Utils
import Views
import RxCocoa

/// Root view of the app, renders a list of hosts on the local network
class BrowseViewController: UIViewController {
    typealias DiffableDataSource = UICollectionViewDiffableDataSource<Int, AddressCluster>

    let serviceController: ServiceController
    let disposeBag = DisposeBag()

    lazy var collectionView = UICollectionView.createList(withHeaders: false)

    lazy var dataSource = DiffableDataSource.create(
        collectionView: collectionView,
        cellBinder: { [weak self] cell, item in
            guard let host = self?.serviceController.host(for: item) else { return }
            cell.configureWithTitle(host.name, subtitle: host.subtitle)
        })

    let networkOverlay = WifiView()

    lazy var searchController = with(UISearchController()) { searchController in
        // Don't move the search bar over the navigation when searching
        searchController.hidesNavigationBarDuringPresentation = false
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

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        view.addSubview(networkOverlay)
        networkOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        collectionView.dataSource = dataSource
        collectionView.delegate = self

#if !targetEnvironment(macCatalyst)
        collectionView.refreshControl = with(UIRefreshControl()) { refresh in
            refresh.addTarget(self, action: #selector(handleTableRefresh(sender:)), for: .valueChanged)
        }
#endif

        navigationItem.searchController = searchController

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
                return !showOverlay
            }
            .observe(on: MainScheduler.instance)
            .bind(to: self.networkOverlay.rx.isHidden)
            .disposed(by: disposeBag)

        // Changing search text searches
        let searchTerm = searchController.searchBar.rx.text
            .trimmedOrNil
            .startWith(nil)
            .distinctUntilChanged()

        // Update the diffable datasource with the latest services, filtering by search term
        Observable
            .combineLatest(serviceController.services, searchTerm)
            .map { (hosts, searchTerm) in
                if let searchTerm {
                    return hosts.filter { $0.matches(search: searchTerm) }
                } else {
                    return hosts
                }
            }
            .observe(on: MainScheduler.instance)
            .debounce(.milliseconds(250), scheduler: MainScheduler.instance)
            .subscribe { [weak self] hosts in
                self?.hostsChanged(to: hosts)
            }
            .disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        for selected in collectionView.indexPathsForSelectedItems ?? [] {
            collectionView.deselectItem(at: selected, animated: true)
        }
    }

    @objc
    func aboutPressed() {
        let about = AboutViewController()
        about.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: about, action: #selector(AboutViewController.done))
        let vc = UINavigationController(rootViewController: about)
        present(vc, animated: true, completion: nil)
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
        var snapshot = NSDiffableDataSourceSnapshot<Int, AddressCluster>()
        snapshot.appendSections([0])
        snapshot.appendItems(hosts.map { $0.addressCluster })
        // rebind _everything_, because hosts can change even if the address list did not
        snapshot.reconfigureItems(snapshot.itemIdentifiers)
        // Don't animate if we're not attached to a window (not laid out) and don't
        // animate the transition to and from empty (because refresh looks bad)
        let animated = collectionView.window != nil && !snapshot.itemIdentifiers.isEmpty && !dataSource.snapshot().itemIdentifiers.isEmpty
        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    @objc func handleTableRefresh(sender: UIControl) {
        // Fake some delays on this because it looks unnatural if things
        // are instant. Refresh the list, then hide the spinner a second later.
        serviceController.restart()
        (splitViewController as? CustomSplitViewController)?.clearSecondaryViewController()
        if let refresh = sender as? UIRefreshControl {
            // iOS devices have pull-to-refresh that we need to stop
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                refresh.endRefreshing()
            }
        }
    }
}

extension BrowseViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let addressCluster = dataSource.itemIdentifier(for: indexPath) else { return }
        let vc = HostViewController(serviceController: serviceController, addressCluster: addressCluster)
        show(vc, sender: self)
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        // capture asap in case the rows move under us
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
}

extension ObservableType where Element == String? {
    var trimmedOrNil: Observable<String?> {
        return self.map { (text: String?) -> String? in
            let t = text?.trimmingCharacters(in: .whitespacesAndNewlines)
            return t?.isEmpty == false ? t : nil
        }
    }
}
