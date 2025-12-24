// Copyright 2016 Thomas Insam. All rights reserved.

import Combine
import SwiftUI
import UIKit

/// View of a single host - lists the services of that host

@Observable
class HostViewModel {
    var cancellables = Set<AnyCancellable>()

    init(serviceController: ServiceController, addressCluster: AddressCluster) {
        self.host = serviceController.clusters.value.first { $0.addressCluster == addressCluster }
        serviceController.clusters
            .host(forAddressCluster: addressCluster)
            .throttle(for: 0.200, scheduler: RunLoop.main, latest: true)
            .map { $0 }
            .assign(to: \.host, on: self)
            .store(in: &cancellables)
    }

    var host: Host?
}

struct HostView: View {
    @Environment(\.openURL) private var openURL

    var viewModel: HostViewModel

    var body: some View {
        if let host = viewModel.host {
            List {
                Section(
                    header: Text(
                        "\(host.addressCluster.sorted.count) address(es)",
                        comment: "Section header for a list of addresses"
                    ),
                    content: {
                        ForEach(host.addressCluster.sorted, id: \.self) { address in
                            ValueCell(title: address, subtitle: nil)
                        }
                    }
                )
                .opacity(host.alive ? 1 : 0.3)

                if let service = host.openableService, let url = service.url {
                    Section {
                        Button(action: {
                            openURL(url)
                        }, label: {
                            Text(service.openAction)
                                .frame(minHeight: 32)
                        })
                    }
                    .listSectionSpacing(16)
                }
                Section(
                    header: Text(
                        "\(host.displayServices.count) service(s)",
                        comment: "Section header for a list of services"
                    ),
                    content: {
                        ForEach(host.displayServices, id: \.ref) { service in
                            NavigationLink(value: service.ref) {
                                DetailCell(
                                    title: service.name,
                                    subtitle: service.typeWithDomain,
                                    copyLabel: String(localized: "Copy type", comment: "Action to copy the type of the service to the clipboard"),
                                    openableService: service,
                                )
                                .opacity(host.alive && service.alive ? 1 : 0.3)
                            }
                        }
                    }
                )
            }
            .navigationTitle(host.name)
            .navigationBarTitleDisplayMode(.large)
        } else {
            EmptyView()
        }
    }
}
