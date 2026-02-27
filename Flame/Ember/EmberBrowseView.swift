// Copyright 2015 Thomas Insam. All rights reserved.

import SwiftUI
import UIKit

/// Root view of the app, renders a list of hosts on the local network

struct EmberBrowseView: View {
    var viewModel: BrowseViewModel

    @Binding
    var selection: AddressCluster?

    @Namespace var selectionBackgroundNamespace

    @Binding var showAbout: Bool

    // Searchable is in the main view
    @State var searchTerm: String = ""

    var body: some View {
        if viewModel.noWifi {
            emptyView
        } else {
            VStack(spacing: 0) {
                HStack {
                    EmberTitleView(
                        title: "Network",
                        subTitle: "\(hosts.count) host(s)"
                    )

                    Button(action: {
                        showAbout = true
                    }, label: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.emberTextHi)
                            .frame(width: 28, height: 28)
                    })
                    .buttonBorderShape(.circle)
                    .buttonStyle(.glass)
                    .accessibilityLabel("About")
                }
                .padding(.leading, 16)
                .padding(.trailing, 8)
                .containerCornerOffset(.leading, sizeToFit: true)

                ScrollView {
                    LazyVStack {

                        ForEach(hosts, id: \.addressCluster) { host in
                            EmberBrowseRow(
                                title: host.name,
                                subtitle: "\(host.displayAddress) • \(host.servicesCount)",
                                copyLabel: String(localized: "Copy address", comment: "Action to copy the address of the host to the clipboard"),
                                openableService: host.openableService,
                                isSelected: selection == host.addressCluster,
                                selectionBackgroundNamespace: selectionBackgroundNamespace,
                                action: {
                                    withAnimation(.bouncy(duration: 0.2)) {
                                        selection = host.addressCluster
                                    }
                                },
                            )
                        }
                    }
                }
                .scrollIndicators(.never)
                .ifiOS {
                    $0.refreshable {
                        selection = nil
                        await viewModel.refresh()
                        // leave the spinner visible while it populates
                        try? await Task.sleep(for: .seconds(2))
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 8) {
                    TextField("", text: $searchTerm, prompt:
                        Text("Search").foregroundStyle(.emberTextLow)
                    )
                        .padding(.leading, 16)
                        .padding(.trailing, 40)
                        .frame(height: 44)
                        .overlay(alignment: .trailing) {
                            Button(action: {
                                searchTerm = ""
                            }, label: {
                                Image(systemName: "xmark.circle.fill")
                                    .frame(width: 44, height: 44)
                            })
                        }
                        .glassEffect(
                            .regular,
                            in: RoundedRectangle(cornerRadius: 22)
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }
        }
    }

    @ViewBuilder
    var emptyView: some View {
        ContentUnavailableView {
            Label("No services found", systemImage: "wifi")
                .font(.emberHeading)
        } description: {
            Text("Connect to a WiFi network to see local services", comment: "Body of a view shown when there are no local services")
                .font(.emberCellTitle)
        }
    }

    var hosts: [Host] {
        viewModel.hosts.filter { $0.matches(search: searchTerm ?? "") }
    }
}

#Preview {
    @Previewable @State var selection: AddressCluster?

    EmberBrowseView(
        viewModel: BrowseViewModelImpl(
            serviceController: ServiceControllerImpl.demo(),
        ),
        selection: $selection,
        showAbout: .constant(false),
    )
    .emberTheme()
}

private class EmptyViewModel: BrowseViewModel {
    var noWifi: Bool = true
    var hosts: [Host] = []
    func refresh() async {}
}

#Preview("Empty") {
    @Previewable @State var selection: AddressCluster?

    EmberBrowseView(
        viewModel: EmptyViewModel(),
        selection: $selection,
        showAbout: .constant(false),
    )
    .emberTheme()
}
