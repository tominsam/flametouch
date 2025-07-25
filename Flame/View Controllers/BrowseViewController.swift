// Copyright 2015 Thomas Insam. All rights reserved.

import Combine
import SwiftUI
import UIKit

/// Root view of the app, renders a list of hosts on the local network

@Observable
final class BrowseViewModel {
    var hosts: [Host] = []

    var selection: Host?

    var noWifi: Bool = false

    var refreshAction: () async -> Void = {}
    var aboutAction: () -> Void = {}
    var exportAction: () -> Void = {}
    var urlAction: (URL) -> Void = { _ in }
    var selectAction: (Host?) -> Void = { _  in }
}

struct BrowseView: View {
    @Bindable
    var viewModel: BrowseViewModel

    @State
    var searchTerm: String = ""

    var body: some View {
        if viewModel.noWifi {
            VStack(alignment: .center, spacing: 20, content: {
                Text("No services found", comment: "Title of a view shown when there are no local services")
                    .font(.title)
                Text("Connect to a WiFi network to see local services", comment: "Body of a view shown when there are no local services")
            })
            .padding()
            .multilineTextAlignment(.center)

        } else {
            List(hosts, id: \.self, selection: $viewModel.selection) { host in
                DetailCell(
                    title: host.name,
                    subtitle: host.subtitle,
                    copyLabel: String(localized: "Copy address", comment: "Action to copy the address of the host to the clipboard"),
                    url: host.url
                )
            }
            .onAppear {
                viewModel.selection = nil
            }
            .onChange(of: viewModel.selection) { _, selection in
                viewModel.selectAction(selection)
            }
            .ifiOS {
                $0.refreshable {
                    await viewModel.refreshAction()
                }
            }
            .searchable(text: $searchTerm)
            .toolbar {
                #if targetEnvironment(macCatalyst)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            await viewModel.refreshAction()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .accessibilityLabel("About")
                        }
                    }
                #else
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            viewModel.aboutAction()
                        } label: {
                            Image(systemName: "info.circle")
                                .accessibilityLabel("About")
                        }
                    }
                #endif
            }
            .environment(\.openURL, OpenURLAction { url in
                viewModel.urlAction(url)
                return .handled
            })
        }
    }

    var hosts: [Host] {
        viewModel.hosts.filter { $0.matches(search: searchTerm) }
    }
}

class BrowseViewController: UIHostingController<BrowseView> {
    var cancellables = Set<AnyCancellable>()

    let serviceController: ServiceController
    var viewModel = BrowseViewModel()

    init(serviceController: ServiceController) {
        self.serviceController = serviceController
        super.init(rootView: BrowseView(viewModel: viewModel))
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.backButtonDisplayMode = .minimal

        viewModel.selectAction = { [weak self] selection in
            guard let host = selection else { return }
            let vc = HostViewController(serviceController: serviceController, host: host)
            self?.show(vc, sender: self)
        }

        viewModel.refreshAction = { [weak self] in
            await self?.refresh()
        }

        viewModel.aboutAction = { [weak self] in
            self?.aboutPressed()
        }

        viewModel.exportAction = { [weak self] in
            self?.exportData(nil)
        }

        viewModel.urlAction = { [weak self] url in
            guard let self else { return }
            AppDelegate.instance.openUrl(url, from: self)
        }

        title = String(
            localized: "Flame",
            comment: "The name of the application"
        )

        // TODO: presenting this from swiftui is still a little complicated
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(exportData(_:))
        )

        // Watch network state and show information about needing wifi when
        // we're not on wifi and there are no services.
        Publishers.CombineLatest(NetworkMonitor.shared.state, serviceController.clusters.map(\.isEmpty))
            .map { state, noservices in
                let nowifi = state.currentConnectionType != .wifi
                let showOverlay = nowifi && noservices
                return showOverlay
            }
            .receive(on: RunLoop.main)
            .sink { [viewModel] value in
                viewModel.noWifi = value
            }
            .store(in: &cancellables)

        serviceController.clusters
            .throttle(for: 0.200, scheduler: RunLoop.main, latest: true)
            .receive(on: RunLoop.main)
            .sink { [viewModel] value in
                viewModel.hosts = value
            }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func aboutPressed() {
        // Doesn't apply to catalyst, we're using the system about support for that.
        #if os(visionOS)
            // open about scene in a new window
            let options = UIWindowScene.ActivationRequestOptions()
            let activity = NSUserActivity(activityType: "org.jerakeen.flametouch.about")
            UIApplication.shared.requestSceneSessionActivation(
                nil,
                userActivity: activity,
                options: options,
                errorHandler: nil
            )
        #else
            // open about view controller modally
            let about = AboutViewController()
            about.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: about, action: #selector(AboutViewController.done))
            let vc = UINavigationController(rootViewController: about)
            present(vc, animated: true, completion: nil)
        #endif
    }

    @objc
    func exportData(_ sender: UIBarButtonItem?) {
        let hosts = serviceController.clusters.value
        guard let url = ServiceExporter.export(hosts: hosts) else { return }
        #if targetEnvironment(macCatalyst)
            let controller = UIDocumentPickerViewController(forExporting: [url])
        #else
            // show system share dialog for this file
            let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            // on iPad, we attach the share sheet to the button that activated it
            controller.popoverPresentationController?.barButtonItem = sender
        #endif
        present(controller, animated: true, completion: nil)
    }

    func refresh() async {
        // Fake some delays on this because it looks unnatural if things
        // are instant. Refresh the list, then hide the spinner a second later.
        await serviceController.restart()
        (splitViewController as? CustomSplitViewController)?.clearSecondaryViewController()
        try? await Task.sleep(for: .seconds(2))
    }
}
