// Copyright 2015 Thomas Insam. All rights reserved.

import SafariServices
import UIKit
import SwiftUI
import Network

@main
struct FlameApp: App {
    let serviceController: ServiceController = ServiceControllerImpl()

    @Environment(\.scenePhase) private var scenePhase

    // Heartbeat task - the network browsers aren't super reliable so stop/start
    // them every 10 seconds
    @State var serviceRefreshTask: Task<Void, Never>?
    @State var flameService: NWListener?

    var body: some Scene {
        WindowGroup {
            MainWindow(serviceController: serviceController)
                .accentColor(Color(red: 204.0 / 255, green: 59.0 / 255, blue: 72.0 / 255, opacity: 1))
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Export", systemImage: "square.and.arrow.up") {
                    // TODO
                }
                .keyboardShortcut(KeyEquivalent("e"), modifiers: [.command, .shift])
                Button("Refresh", systemImage: "arrow.clockwise") {
                    Task {
                        await serviceController.restart()
                    }
                }
                .keyboardShortcut(KeyEquivalent("r"), modifiers: [.command])
            }
        }
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .active:
                start()
            case .background:
                stop()
            case .inactive:
                break
            @unknown default:
                break
            }
        }

        WindowGroup(id: "about") {
            AboutView()
        }
        .defaultSize(width: 480, height: 640)
    }

    func start() {
        guard serviceRefreshTask == nil else {
            return
        }

        serviceRefreshTask = Task {
            ELog("Starting heartbeat")
            await serviceController.start()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                if Task.isCancelled { break }
                ELog("tick")
                await serviceController.stop()
                await serviceController.start()
            }
            ELog("Stopping heartbeat")
            await serviceController.stop()
        }

        if flameService == nil {
            // Advertise a local service called flametouch, partly as a demo, partly
            // so you can tell there's _something_ there even if there are no other
            // services on the network.
            flameService = try? NWListener(
                service: .init(name: UIDevice.current.name, type: "_flametouch._tcp."),
                using: .tcp
            )
            flameService?.stateUpdateHandler = { newState in
                ELog("Publish state is \(newState)")
            }
            flameService?.newConnectionHandler = { connection in
                connection.cancel()
            }
            flameService?.start(queue: .main)
        }
    }
    

    func stop() {
        serviceRefreshTask?.cancel()
        serviceRefreshTask = nil

        flameService?.cancel()
        flameService = nil
    }
}

struct MainWindow: View {
    let serviceController: ServiceController
    @State var addressCluster: AddressCluster?
    @State var serviceRef: ServiceRef?
    @State var showAbout: Bool = false
    @State var searchText: String = ""

    @State
    var path = NavigationPath()

    var body: some View {
        NavigationSplitView(sidebar: {
            BrowseView(
                viewModel: BrowseViewModel(serviceController: serviceController),
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
                        HostView(
                            viewModel: HostViewModel(serviceController: serviceController, addressCluster: addressCluster),
                            selection: $serviceRef,
                        )
                    }
                }
                    .navigationDestination(for: ServiceRef.self) { serviceRef in
                        ServiceView(
                            viewModel: ServiceViewModel(serviceController: serviceController, serviceRef: serviceRef),
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
        // Put before about sheet so that links in the about pane just open safari
        .modifier(SafariViewControllerViewModifier())
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }
}
