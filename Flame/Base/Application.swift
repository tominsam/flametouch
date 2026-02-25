// Copyright 2015 Thomas Insam. All rights reserved.

import SafariServices
import UIKit
import SwiftUI
import Network

@main
struct FlameApp: App {
    // Switch between UI layers: true = Ember (new), false = Slate (preserved)
    @AppStorage("useEmberUI") var useEmberUI = false

    let serviceController: ServiceController = ServiceControllerImpl()

    @Environment(\.scenePhase) private var scenePhase

    // Heartbeat task - the network browsers aren't super reliable so stop/start
    // them every 10 seconds
    @State var showAbout = false
    @State var serviceRefreshTask: Task<Void, Never>?
    @State var flameService: NWListener?

    var body: some Scene {
        WindowGroup {
            Group {
                if useEmberUI {
                    EmberMainWindow(serviceController: serviceController, showAbout: $showAbout)
                } else {
                    SlateMainWindow(serviceController: serviceController, showAbout: $showAbout)
                }
            }
            .modifier(SafariViewControllerViewModifier())
            .sheet(isPresented: $showAbout) {
                if useEmberUI {
                    SlateAboutView(useEmberUI: $useEmberUI)
                        .emberTheme()
                } else {
                    SlateAboutView(useEmberUI: $useEmberUI)
                }
            }
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
            if useEmberUI {
                SlateAboutView(useEmberUI: $useEmberUI)
                    .emberTheme()
            } else {
                SlateAboutView(useEmberUI: $useEmberUI)
            }
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

