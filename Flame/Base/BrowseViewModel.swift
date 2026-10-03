// Copyright 2015 Thomas Insam. All rights reserved.

import SwiftUI
import UIKit

@MainActor
protocol BrowseViewModel: Observable {
    var noWifi: Bool { get }
    var hosts: [Host] { get }
    func refresh() async
    var export: ExportServicesDocument? { get }
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

    var export: ExportServicesDocument? {
        ExportServicesDocument(serviceController: serviceController)
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

