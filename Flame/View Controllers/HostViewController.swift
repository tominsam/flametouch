// Copyright 2016 Thomas Insam. All rights reserved.

import Combine
import SwiftUI
import UIKit

/// View of a single host - lists the services of that host

class HostViewModel: ObservableObject {
    @Published
    var host: Host?

    @Published
    var selection: Service?
}

struct HostView: View {
    @ObservedObject
    var viewModel: HostViewModel

    var body: some View {
        if let host = viewModel.host {
            List(selection: $viewModel.selection) {
                Section(
                    header: Text(
                        "\(host.addressCluster.sorted.count, specifier: "%llu") address(es)",
                        comment: "Section header for a list of addresses"
                    ),
                    content: {
                        ForEach(host.addressCluster.sorted, id: \.self) { address in
                            ValueCell(title: address, subtitle: nil)
                        }
                    }
                )
                .opacity(host.alive ? 1 : 0.3)

                Section(
                    header: Text(
                        "\(host.displayServices.count, specifier: "%llu") service(s)",
                        comment: "Section header for a list of services"
                    ),
                    content: {
                        ForEach(host.displayServices) { service in
                            DetailCell(
                                title: service.name,
                                subtitle: service.typeWithDomain,
                                copyLabel: String(localized: "Copy type", comment: "Action to copy the type of the service to the clipboard"),
                                url: service.url
                            )
                            .opacity(host.alive && service.alive ? 1 : 0.3)
                        }
                    }
                )
            }
            .onAppear {
                viewModel.selection = nil
            }
            .navigationTitle(host.name)
        } else {
            EmptyView()
        }
    }
}

class HostViewController: UIHostingController<HostView>, UICollectionViewDelegate {
    var viewModel = HostViewModel()
    var cancellables = Set<AnyCancellable>()

    required init(serviceController: ServiceController, host: Host) {
        super.init(rootView: HostView(viewModel: viewModel))
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.backButtonDisplayMode = .minimal

        serviceController.clusters
            .host(forAddressCluster: host.addressCluster)
            .throttle(for: 0.200, scheduler: RunLoop.main, latest: true)
            .map { $0 }
            .sink { [viewModel] value in
                viewModel.host = value
            }
            .store(in: &cancellables)

        viewModel.$selection
            .compactMap { $0 }
            .sink { [weak self] service in
                let vc = ServiceViewController(serviceController: serviceController, service: service)
                self?.show(vc, sender: self)
            }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}
