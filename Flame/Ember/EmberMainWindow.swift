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
            showAbout: $showAbout,
        )
    }

    @ViewBuilder
    func detailView(for addressCluster: AddressCluster) -> some View {
        EmberHostView(
            viewModel: EmberHostViewModel(serviceController: serviceController, addressCluster: addressCluster),
        )
    }

    @ViewBuilder
    var secondaryView: some View {
        if let addressCluster {
            detailView(for: addressCluster)
        } else if !serviceController.clusters.isEmpty {
            ContentUnavailableView {
                Label("Choose a host", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.emberHeading)
                    .foregroundStyle(.emberTextMid)
            } description: {
            }
        } else {
            Color(.emberBase)
        }
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                // Phone layout
                NavigationStack(path: $path) {
                    mainView
                        .navigationDestination(item: $addressCluster, destination: {
                            detailView(for: $0)
                                .background {
                                    Color(.emberBase)
                                        .ignoresSafeArea(.all)
                                }
                        })
                        .background {
                            Color(.emberBase)
                                .ignoresSafeArea(.all)
                        }
                }
            } else {
                // Pad layout
                NavigationSplitView {
                    mainView
                        .toolbar(removing: .sidebarToggle)
                        .background {
                            Color(.emberBase)
                                .ignoresSafeArea(.all)
                        }
                } detail: {
                    secondaryView
                        .background {
                            Color(.emberBase)
                                .ignoresSafeArea(.all)
                        }
                }
                .navigationSplitViewStyle(.balanced)
            }
        }
        .emberTheme()
        .onChange(of: serviceController.host(for: addressCluster)) { _, host in
            if addressCluster != nil, host == nil {
                addressCluster = nil
            }
        }
    }
}
