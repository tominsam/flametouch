// Copyright 2015 Thomas Insam. All rights reserved.

import Combine
import SwiftUI
import UIKit

/// Root view of the app, renders a list of hosts on the local network

@MainActor @Observable
final class BrowseViewModel {
    let serviceController: ServiceController

    var hosts: [Host] = []
    var noWifi: Bool = false
    var actions: BrowseActions?

    var cancellables = Set<AnyCancellable>()

    init(serviceController: ServiceController) {
        self.serviceController = serviceController
        self.hosts = serviceController.clusters.value

        // Watch network state and show information about needing wifi when
        // we're not on wifi and there are no services.
        Publishers.CombineLatest(
            NetworkMonitor.shared.$state,
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
    var viewModel: BrowseViewModel

    @Binding
    var selection: AddressCluster?

    // Searchable is in the main view
    let searchTerm: String

    var body: some View {
        if viewModel.noWifi {
            emptyView
        } else {
            List(hosts, id: \.addressCluster, selection: $selection) { host in
                DetailCell(
                    title: host.name,
                    subtitle: host.subtitle,
                    copyLabel: String(localized: "Copy address", comment: "Action to copy the address of the host to the clipboard"),
                    openableService: host.openableService,
                )
            }
            .listStyle(.plain)
            .ifiOS {
                $0.refreshable {
                    selection = nil
                    await viewModel.refresh()
                    // leave the spinner visible while it populates
                    try? await Task.sleep(for: .seconds(2))
                }
            }
            .navigationTitle("Flame")
            .navigationBarTitleDisplayMode(.inline)
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

    var hosts: [Host] {
        viewModel.hosts.filter { $0.matches(search: searchTerm) }
    }
}

#Preview {
    @Previewable @State var selection: AddressCluster?

    NavigationStack {
        BrowseView(
            viewModel: BrowseViewModel(
                serviceController: ServiceControllerImpl.demo(),
            ),
            selection: $selection,
            searchTerm: ""
        )
    }
}
