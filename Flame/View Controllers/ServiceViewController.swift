// Copyright 2016 Thomas Insam. All rights reserved.

import Combine
import SwiftUI
import UIKit

/// Shows the details of a particular service on a particular host

@Observable
class ServiceViewModel {
    var service: Service
    var alive = true
    var highlight = true

    init(service: Service) {
        self.service = service
    }
}

struct ServiceView: View {
    @Bindable
    var viewModel: ServiceViewModel

    var body: some View {
        List {
            Section("Core") {
                ValueCell(
                    title: String(localized: "Name", comment: "Heading for a cell showing a service name"),
                    subtitle: viewModel.service.name
                )
                ValueCell(
                    title: String(localized: "Type", comment: "Heading for a cell showing a service type"),
                    subtitle: viewModel.service.type,
                    url: viewModel.service.url
                )
                if let domain = viewModel.service.domain {
                    ValueCell(title: "Domain", subtitle: domain)
                }

                ForEach(viewModel.service.addressCluster.sorted, id: \.self) { address in
                    ValueCell(title: "Address", subtitle: address)
                }

                ValueCell(title: "Port", subtitle: String(viewModel.service.port))
            }

            let sortedData = viewModel.service.data.sorted { $0.key.lowercased() < $1.key.lowercased() }
            if !sortedData.isEmpty {
                Section("Data") {
                    ForEach(sortedData, id: \.key) { data in
                        ValueCell(title: data.key, subtitle: data.value, url: realUrl(from: data.value))
                    }
                }
            }
        }
        .opacity(viewModel.alive ? 1 : 0.3)
        .navigationTitle(viewModel.service.typeWithDomain)
        .navigationBarTitleDisplayMode(.large)
    }

    func realUrl(from string: String) -> URL? {
        if let url = URL(string: string), url.scheme != nil, url.host != nil {
            return url
        }
        return nil
    }
}

class ServiceViewController: UIHostingController<ModifiedContent<ServiceView, SafariViewControllerViewModifier>> {
    var cancellables = Set<AnyCancellable>()
    var viewModel: ServiceViewModel

    required init(serviceController: ServiceController, service: Service) {
        self.viewModel = ServiceViewModel(service: service)
        super.init(rootView: ServiceView(viewModel: viewModel).modifier(SafariViewControllerViewModifier()))
        navigationItem.largeTitleDisplayMode = .never

        serviceController.clusters
            .map { [service] hosts in
                hosts.serviceMatching(service: service)
            }
            .throttle(for: 0.200, scheduler: RunLoop.main, latest: true)
            .receive(on: RunLoop.main)
            .sink { [viewModel] service in
                if let found = service {
                    viewModel.service = found
                    viewModel.alive = found.alive
                } else {
                    // this service is gone. Keep the addresses in case it comes back.
                    viewModel.alive = false
                }
            }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}
