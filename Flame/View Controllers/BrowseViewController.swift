// Copyright 2015 Thomas Insam. All rights reserved.

import Combine
import SwiftUI
import UIKit

/// Root view of the app, renders a list of hosts on the local network

@Observable
final class BrowseViewModel {
    let serviceController: ServiceController

    var hosts: [Host] = []
    var noWifi: Bool = false
    var actions: BrowseActions?

    var cancellables = Set<AnyCancellable>()

    init(serviceController: ServiceController) {
        self.serviceController = serviceController

        // Watch network state and show information about needing wifi when
        // we're not on wifi and there are no services.
        Publishers.CombineLatest(
            NetworkMonitor.shared.state,
            serviceController.clusters.map(\.isEmpty)
        )
            .map { state, isEmpty in
                let nowifi = state.currentConnectionType != .wifi
                let showOverlay = nowifi && isEmpty
                return showOverlay
            }
            .receive(on: RunLoop.main)
            .assign(to: \.noWifi, on: self)
            .store(in: &cancellables)

        serviceController.clusters
            .throttle(for: 0.200, scheduler: RunLoop.main, latest: true)
            .receive(on: RunLoop.main)
            .assign(to: \.hosts, on: self)
            .store(in: &cancellables)
    }

    func refresh() async {
        // Fake some delays on this because it looks unnatural if things
        // are instant. Refresh the list, then hide the spinner a second later.
        await serviceController.restart()
    }
}

struct BrowseActions {
    let aboutAction: () -> Void
    let selectAction: (Host?) -> Void
}

struct BrowseView: View {
    @Bindable
    var viewModel: BrowseViewModel

    @State
    var searchTerm: String = ""

    @State
    var selection: Host?

    var body: some View {
        if viewModel.noWifi {
            emptyView
        } else {
            List(hosts, id: \.self, selection: $selection) { host in
                DetailCell(
                    title: host.name,
                    subtitle: host.subtitle,
                    copyLabel: String(localized: "Copy address", comment: "Action to copy the address of the host to the clipboard"),
                    openableService: host.openableService,
                )
            }
            .listStyle(.plain)
            .onAppear {
                selection = nil
            }
            .onChange(of: selection) { _, selection in
                viewModel.actions?.selectAction(selection)
            }
            .ifiOS {
                $0.refreshable {
                    selection = nil
                    await viewModel.refresh()
                    // leave the spinner visible while it populates
                    try? await Task.sleep(for: .seconds(2))
                }
            }
            .searchable(text: $searchTerm)
            .navigationTitle("Flame")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
        }
    }

    @ViewBuilder
    var emptyView: some View {
        VStack(alignment: .center, spacing: 20, content: {
            Text("No services found", comment: "Title of a view shown when there are no local services")
                .font(.title)
            Text("Connect to a WiFi network to see local services", comment: "Body of a view shown when there are no local services")
        })
        .padding()
        .multilineTextAlignment(.center)
    }


    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
#if targetEnvironment(macCatalyst)
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                Task {
                    await viewModel.refresh()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .accessibilityLabel("Refresh")
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

    var hosts: [Host] {
        viewModel.hosts.filter { $0.matches(search: searchTerm) }
    }
}

class BrowseViewController: UIHostingController<ModifiedContent<BrowseView, SafariViewControllerViewModifier>> {
    let serviceController: ServiceController
    var viewModel: BrowseViewModel

    init(serviceController: ServiceController) {
        self.serviceController = serviceController
        self.viewModel = BrowseViewModel(serviceController: serviceController)
        super.init(rootView:
            BrowseView(viewModel: viewModel)
            .modifier(SafariViewControllerViewModifier())
        )

        // Set after super.init
        viewModel.actions = BrowseActions(
            aboutAction: { [weak self] in
                self?.aboutPressed()
            },
            selectAction: { [weak self] selection in
                guard let host = selection else { return }
                let vc = HostViewController(serviceController: serviceController, host: host)
                self?.show(vc, sender: self)
            }
        )
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func aboutPressed() {
        // Doesn't apply to catalyst, we're using the system about support for that.
        let about = AboutViewController()
        about.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: about, action: #selector(AboutViewController.done))
        let vc = UINavigationController(rootViewController: about)
        present(vc, animated: true, completion: nil)
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
