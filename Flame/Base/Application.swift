// Copyright 2015 Thomas Insam. All rights reserved.

import SafariServices
import UIKit
import SwiftUI
import Network
import UniformTypeIdentifiers

@main
struct FlameApp: App {
    let serviceController: ServiceController = ServiceControllerImpl()

    @Environment(\.scenePhase) private var scenePhase

    // Heartbeat task - the network browsers aren't super reliable so stop/start
    // them every 10 seconds
    @State private var showSettings = false
    @State private var exportingFile = false
    @State private var serviceRefreshTask: Task<Void, Never>?
    @State private var flameService: NWListener?

    var body: some Scene {
        WindowGroup {
            EmberMainWindow(serviceController: serviceController, showSettings: $showSettings)
                .modifier(SafariViewControllerViewModifier())
                .sheet(isPresented: $showSettings) {
                    NavigationStack {
                        SettingsView()
                    }
                        .emberTheme()
                }
                .fileExporter(
                    isPresented: $exportingFile,
                    document: ExportServicesDocument(serviceController: serviceController),
                    contentType: .json,
                    defaultFilename: "flame-export.json",
                    onCompletion: { _ in
                        print(1)
                    }
                )
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Export", systemImage: "square.and.arrow.up") {
                    exportingFile = true
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

        WindowGroup(id: "settings") {
            SettingsView()
                .emberTheme()
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
            flameService = try? NWListener(using: .tcp, on: 1812)
            flameService?.service = .init(name: UIDevice.current.name, type: "_flametouch._tcp.")
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
