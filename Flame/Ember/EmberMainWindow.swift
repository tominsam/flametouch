// Copyright 2015 Thomas Insam. All rights reserved.

import SafariServices
import SwiftUI
import UIKit

struct EmberMainWindow: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    let serviceController: ServiceController
    @State var addressCluster: AddressCluster?
    @State var serviceRef: ServiceRef?
    @Binding var showAbout: Bool
    @State var searchText: String = ""

    @State
    var path = NavigationPath()

    var mainView: some View {
        EmberBrowseView(
            viewModel: BrowseViewModelImpl(serviceController: serviceController),
            selection: $addressCluster,
            searchTerm: searchText
        )
    }

    @ViewBuilder
    func detailView(for addressCluster: AddressCluster) -> some View {
        EmberHostView(
            viewModel: EmberHostViewModel(serviceController: serviceController, addressCluster: addressCluster),
        )
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                NavigationStack(path: $path) {
                    mainView
                        .background(.background)
                        .navigationDestination(item: $addressCluster, destination: { addressCluster in
                            detailView(for: addressCluster)
                                .background(.background)
                        })
                }
            } else {
                HStack {
                    mainView
                        .containerRelativeFrame(.horizontal) { width, _ in
                            min(width / 3, 300)
                        }

                    if let addressCluster {
                        detailView(for: addressCluster)
                    } else {
                        ContentUnavailableView {
                            Label("Choose a host", systemImage: "point.3.connected.trianglepath.dotted")
                                .font(.emberHeading)
                        } description: {
                            Text("Something something someintg")
                                .font(.emberCellTitle)
                        }
                    }

                }
            }
        }
        .emberTheme()
    }
}
