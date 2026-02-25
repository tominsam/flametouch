// Copyright 2015 Thomas Insam. All rights reserved.

import SafariServices
import SwiftUI
import UIKit

struct EmberMainWindow: View {
    let serviceController: ServiceController
    @State var addressCluster: AddressCluster?
    @State var serviceRef: ServiceRef?
    @Binding var showAbout: Bool
    @State var searchText: String = ""

    @State
    var path = NavigationPath()

    var body: some View {
        NavigationSplitView(sidebar: {
            EmberBrowseView(
                viewModel: EmberBrowseViewModelImpl(serviceController: serviceController),
                selection: $addressCluster,
                searchTerm: searchText
            )
            .searchable(text: $searchText, placement: .toolbarPrincipal)
            .navigationSplitViewColumnWidth(ideal: 400)
#if !targetEnvironment(macCatalyst)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: {
                        showAbout = true
                    }, label: {
                        Label("About", systemImage: "info.circle")
                    })
                }
            }
#endif
            .toolbar(removing: .sidebarToggle)
        }, detail: {
            NavigationStack(path: $path, root: {
                Group {
                    if let addressCluster {
                        EmberHostView(
                            viewModel: EmberHostViewModel(serviceController: serviceController, addressCluster: addressCluster),
                            selection: $serviceRef,
                        )
                    }
                }
                    .navigationDestination(for: ServiceRef.self) { serviceRef in
                        EmberServiceView(
                            viewModel: EmberServiceViewModel(serviceController: serviceController, serviceRef: serviceRef),
                        )
                    }
                    .onChange(of: serviceRef) {
                        if let serviceRef {
                            path.append(serviceRef)
                        }
                    }
                    .onChange(of: path) {
                        if path.isEmpty {
                            serviceRef = nil
                        }
                    }
            })
        })
        .accentColor(Color(red: 204.0 / 255, green: 59.0 / 255, blue: 72.0 / 255, opacity: 1))
    }
}
