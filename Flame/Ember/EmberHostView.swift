// Copyright 2016 Thomas Insam. All rights reserved.

import SwiftUI
import UIKit
import Flow

/// View of a single host - lists the services of that host

@MainActor @Observable
class EmberHostViewModel {
    let serviceController: ServiceController
    let addressCluster: AddressCluster

    var host: Host? {
        serviceController.clusters.first { $0.addressCluster == addressCluster }
    }

    init(serviceController: ServiceController, addressCluster: AddressCluster) {
        self.serviceController = serviceController
        self.addressCluster = addressCluster
    }
}

struct EmberHostView: View {
    @Environment(\.openURL) private var openURL

    var viewModel: EmberHostViewModel

    @State
    var selected: Set<ServiceRef> = Set()

    var body: some View {
        if let host = viewModel.host {
            VStack(spacing: 0) {
                Text(host.name)
                    .font(.emberHeading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                ScrollView {
                    VStack(spacing: 0) {
                        addresses(for: host)
                        actions(for: host)
                        services(for: host)
                        Color(.clear).frame(height: 1)
                    }
                }
                .scrollIndicators(.never)
            }
        }
    }

    @ViewBuilder
    func addresses(for host: Host) -> some View {
        HFlow(spacing: 4, distributeItemsEvenly: true) {
            ForEach(host.addressCluster.sorted, id: \.self) { address in
                Text(address)
                    .lineLimit(1)
                    .font(.emberSectionHeader)
                    .foregroundStyle(.emberTintDim)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background {
                        FilledStrokedRoundRect(fill: .emberCard, stroke: .emberTintDim, radius: 20)
                            .padding(4)
                    }
                    .contextMenu {
                        Button(action: {}, label: {
                            Text("oo")
                        })
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .opacity(host.alive ? 1 : 0.3)
    }

    @ViewBuilder
    func actions(for host: Host) -> some View {
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
    }

    @ViewBuilder
    func services(for host: Host) -> some View {
        Text(
            "\(host.displayServices.count) service(s)",
            comment: "Section header for a list of services"
        )
        .font(.emberSectionHeader)
        .textCase(.uppercase)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)

        LazyVStack(spacing: 8) {
            ForEach(host.displayServices, id: \.ref) { service in
                let isSelected = selected.contains(service.ref)

                VStack {
                    EmberHostRow(
                        title: service.name,
                        subtitle: service.typeWithDomain,
                        isAlive: host.alive && service.alive,
                        isSelected: isSelected,
                        url: service.url,
                        action: {
                            withAnimation(.easeInOut) {
                                if isSelected {
                                    selected.remove(service.ref)
                                } else {
                                    selected.insert(service.ref)
                                }
                            }
                        }
                    )
                    .geometryGroup()
                    if isSelected {
                        services(for: service)
                            .padding(.leading, 40)
                            .padding(.trailing, 16)
                            .padding(.bottom, 16)
                    }
                }
                .background {
                    if isSelected {
                        Color(.emberCard)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func services(for service: Service) -> some View {
        VStack(spacing: 0) {
            let sortedData = service.data.sorted { $0.key.lowercased() < $1.key.lowercased() }

            EmberServiceRow(title: "Port", subtitle: "\(service.port)", url: nil)
                .padding(.horizontal, 16)
            ForEach(sortedData, id: \.key) { data in
                Color(.emberElevated)
                    .frame(height: 2)
                EmberServiceRow(title: data.key, subtitle: data.value, url: nil)
                    .padding(.horizontal, 16)
            }
        }
        .background {
            FilledStrokedRoundRect(fill: .emberInset, stroke: .emberElevated, radius: 12)
        }
    }

}

#Preview {
    EmberHostView(
        viewModel: EmberHostViewModel(
            serviceController: ServiceControllerImpl.demo(),
            addressCluster: .from(addresses: ["192.168.0.188"], hostnames: []),
        )
    )
    .emberTheme()
}
