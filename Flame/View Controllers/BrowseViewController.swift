// Copyright 2015 Thomas Insam. All rights reserved.

import Combine
import SwiftUI
import UIKit

/// Root view of the app, renders a list of hosts on the local network

@Observable
final class BrowseViewModel { // }: ObservableObject {
    let serviceController: ServiceController

    var hosts: [Host] = []
    var selection: Host?
    var noWifi: Bool = false
    var actions: BrowseActions?

    var cancellables = Set<AnyCancellable>()

    init(serviceController: ServiceController) {
        self.serviceController = serviceController

        // Watch network state and show information about needing wifi when
        // we're not on wifi and there are no services.
        Publishers.CombineLatest(NetworkMonitor.shared.state, serviceController.clusters.map(\.isEmpty))
            .map { state, noservices in
                let nowifi = state.currentConnectionType != .wifi
                let showOverlay = nowifi && noservices
                return showOverlay
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.noWifi = value
            }
            .store(in: &cancellables)

        serviceController.clusters
            .throttle(for: 0.200, scheduler: RunLoop.main, latest: true)
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.hosts = value
            }
            .store(in: &cancellables)

    }

    func refresh() async {
        // Fake some delays on this because it looks unnatural if things
        // are instant. Refresh the list, then hide the spinner a second later.
        selection = nil
        await serviceController.restart()
        try? await Task.sleep(for: .seconds(2))
    }
}

struct BrowseActions {
    let aboutAction: () -> Void
    let urlAction: (URL) -> Void
    let selectAction: (Host?) -> Void
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
                    url: host.openableService?.url,
                )
            }
            .onAppear {
                viewModel.selection = nil
            }
            .onChange(of: viewModel.selection) { _, selection in
                viewModel.actions?.selectAction(selection)
            }
            .ifiOS {
                $0.refreshable {
                    await viewModel.refresh()
                }
            }
            .searchable(text: $searchTerm)
            .navigationTitle("Flame")
            .toolbar {
                #if targetEnvironment(macCatalyst)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            Task {
                                await viewModel.actions?.refreshAction()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .accessibilityLabel("About")
                        }
                    }
                #else
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            viewModel.actions?.aboutAction()
                        } label: {
                            Image(systemName: "info.circle")
                                .accessibilityLabel("About")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if let export = ServiceExporter.export(hosts: hosts) {
                            ShareLink(item: export)
                        }
                    }
                #endif
            }
            .environment(\.openURL, OpenURLAction { url in
                viewModel.actions?.urlAction(url)
                return .handled
            })
        }
    }

    var hosts: [Host] {
        viewModel.hosts.filter { $0.matches(search: searchTerm) }
    }
}

class BrowseViewController: UIHostingController<BrowseView> {
    let serviceController: ServiceController
    var viewModel: BrowseViewModel

    init(serviceController: ServiceController) {
        self.serviceController = serviceController
        self.viewModel = BrowseViewModel(serviceController: serviceController)
        super.init(rootView: BrowseView(viewModel: viewModel))
//        navigationItem.largeTitleDisplayMode = .always
//        navigationItem.backButtonDisplayMode = .minimal

        let actions = BrowseActions(
            aboutAction: { [weak self] in
                self?.aboutPressed()
            },
            urlAction: { [weak self] url in
                guard let self else { return }
                AppDelegate.instance.openUrl(url, from: self)
            },
            selectAction: { [weak self] selection in
                guard let host = selection else { return }
                let vc = HostViewController(serviceController: serviceController, host: host)
                self?.show(vc, sender: self)
            }
        )

        viewModel.actions = actions
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
}

#Preview {
    NavigationStack {
        BrowseView(
            viewModel: BrowseViewModel(
                serviceController: ServiceControllerImpl.demo()
            )
        )
    }
}
