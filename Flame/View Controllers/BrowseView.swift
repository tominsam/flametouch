// Copyright 2015 Thomas Insam. All rights reserved.

import SwiftUI
import UIKit

/// Root view of the app, renders a list of hosts on the local network

@MainActor
protocol BrowseViewModel: Observable {
    var noWifi: Bool { get }
    var hosts: [Host] { get }
    func refresh() async
}

@MainActor @Observable
final class BrowseViewModelImpl: BrowseViewModel {
    let serviceController: ServiceController

    var noWifi: Bool {
        let nowifi = NetworkMonitor.shared.state.currentConnectionType != .wifi
        let isEmpty = serviceController.clusters.isEmpty
        return nowifi && isEmpty
    }

    var hosts: [Host] {
        serviceController.clusters
    }

    init(serviceController: ServiceController) {
        self.serviceController = serviceController
    }

    func refresh() async {
        // Fake some delays on this because it looks unnatural if things
        // are instant. Refresh the list, then hide the spinner a second later.
        await serviceController.restart()
    }
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
        ContentUnavailableView {
            Label("No services found", systemImage: "wifi")
        } description: {
            Text("Connect to a WiFi network to see local services", comment: "Body of a view shown when there are no local services")
        }
    }

    var hosts: [Host] {
        viewModel.hosts.filter { $0.matches(search: searchTerm) }
    }
}

#Preview {
    @Previewable @State var selection: AddressCluster?

    NavigationStack {
        BrowseView(
            viewModel: BrowseViewModelImpl(
                serviceController: ServiceControllerImpl.demo(),
            ),
            selection: $selection,
            searchTerm: ""
        )
    }
}

private class EmptyViewModel: BrowseViewModel {
    var noWifi: Bool = true
    var hosts: [Host] = []
    func refresh() async {}
}

#Preview("Empty") {
    @Previewable @State var selection: AddressCluster?

    NavigationStack {
        BrowseView(
            viewModel: EmptyViewModel(),
            selection: $selection,
            searchTerm: ""
        )
    }
}
