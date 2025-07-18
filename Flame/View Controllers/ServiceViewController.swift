// Copyright 2016 Thomas Insam. All rights reserved.

import Combine
import SwiftUI
import UIKit

/// Shows the details of a particular service on a particular host

@Observable
class ServiceViewModel {
    var service: Service?
    var alive = true
    var highlight = true
    var tapAction: (URL) -> Void = { _ in }
}

struct ServiceView: View {
    @Bindable
    var viewModel: ServiceViewModel

    var body: some View {
        if let service = viewModel.service {
            List {
                Section("Core") {
                    ValueCell(
                        title: String(localized: "Name", comment: "Heading for a cell showing a service name"),
                        subtitle: service.name
                    )
                    ValueCell(
                        title: String(localized: "Type", comment: "Heading for a cell showing a service type"),
                        subtitle: service.type,
                        url: service.url,
                        tapAction: viewModel.tapAction
                    )
                    if let domain = service.domain {
                        ValueCell(title: "Domain", subtitle: domain)
                    }

                    ForEach(service.addressCluster.sorted, id: \.self) { address in
                        ValueCell(title: "Address", subtitle: address)
                    }

                    ValueCell(title: "Port", subtitle: String(service.port))
                }

                let sortedData = service.data.sorted { $0.key.lowercased() < $1.key.lowercased() }
                if !sortedData.isEmpty {
                    Section("Data") {
                        ForEach(sortedData, id: \.key) { data in
                            ValueCell(title: data.key, subtitle: data.value, url: realUrl(from: data.value), tapAction: viewModel.tapAction)
                        }
                    }
                }
            }
            .opacity(viewModel.alive ? 1 : 0.3)
            .navigationTitle(service.typeWithDomain)
        } else {
            EmptyView()
        }
    }

    func realUrl(from string: String) -> URL? {
        if let url = URL(string: string), url.scheme != nil, url.host != nil {
            return url
        }
        return nil
    }
}

class ServiceViewController: UIHostingController<ServiceView>, UICollectionViewDelegate {
    var cancellables = Set<AnyCancellable>()
    var viewModel = ServiceViewModel()

    required init(serviceController: ServiceController, service: Service) {
        super.init(rootView: ServiceView(viewModel: viewModel))
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.backButtonDisplayMode = .minimal

        serviceController.clusters
            .map { [service] hosts in
                hosts.serviceMatching(service: service)
            }
            .throttle(for: 0.200, scheduler: RunLoop.main, latest: true)
            .receive(on: RunLoop.main)
            .sink { [viewModel] service in
                if let found = service {
                    viewModel.service = service
                    viewModel.alive = found.alive
                } else {
                    // this service is gone. Keep the addresses in case it comes back.
                    viewModel.alive = false
                }
            }
            .store(in: &cancellables)

        viewModel.tapAction = { url in
            AppDelegate.instance.openUrl(url, from: self)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}
