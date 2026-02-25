// Copyright 2016 Thomas Insam. All rights reserved.

import SwiftUI
import UIKit

/// Shows the details of a particular service on a particular host

@MainActor @Observable
class SlateServiceViewModel {
    let serviceController: ServiceController
    let serviceRef: ServiceRef

    var service: Service? {
        serviceController.clusters.serviceMatching(serviceRef: serviceRef)
    }

    var alive: Bool {
        service?.alive ?? false
    }

    init(serviceController: ServiceController, serviceRef: ServiceRef) {
        self.serviceController = serviceController
        self.serviceRef = serviceRef
    }
}

struct SlateServiceView: View {
    var viewModel: SlateServiceViewModel

    var body: some View {
        List {
            Section("Core") {
                SlateValueCell(
                    title: String(localized: "Name", comment: "Heading for a cell showing a service name"),
                    subtitle: viewModel.service?.name
                )
                SlateValueCell(
                    title: String(localized: "Type", comment: "Heading for a cell showing a service type"),
                    subtitle: viewModel.service?.type,
                    url: viewModel.service?.url
                )
                if let domain = viewModel.service?.domain {
                    SlateValueCell(title: "Domain", subtitle: domain)
                }

                ForEach(viewModel.service?.addressCluster.sorted ?? [], id: \.self) { address in
                    SlateValueCell(title: "Address", subtitle: address)
                }

                SlateValueCell(title: "Port", subtitle: String(viewModel.service?.port ?? 0))
            }

            let sortedData = viewModel.service?.data.sorted { $0.key.lowercased() < $1.key.lowercased() } ?? []
            if !sortedData.isEmpty {
                Section("Data") {
                    ForEach(sortedData, id: \.key) { data in
                        SlateValueCell(title: data.key, subtitle: data.value, url: realUrl(from: data.value))
                    }
                }
            }
        }
        .opacity(viewModel.alive ? 1 : 0.3)
        .navigationTitle(viewModel.service?.typeWithDomain ?? "")
        .navigationBarTitleDisplayMode(.large)
    }

    func realUrl(from string: String) -> URL? {
        if let url = URL(string: string), url.scheme != nil, url.host != nil {
            return url
        }
        return nil
    }
}
