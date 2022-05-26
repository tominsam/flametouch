// Copyright 2016 Thomas Insam. All rights reserved.

import Foundation
import Network

// https://digitalbunker.dev/native-network-monitoring-in-swift/

extension NWInterface.InterfaceType: CaseIterable {
    public static var allCases: [NWInterface.InterfaceType] = [
        .other,
        .wifi,
        .cellular,
        .loopback,
        .wiredEthernet
    ]
}

final class NetworkMonitor {
    static let shared = NetworkMonitor()

    typealias Callback = ((NetworkMonitor) -> Void)
    private var callbacks: [NSObject: Callback] = [:]

    private let queue = DispatchQueue(label: "NetworkConnectivityMonitor")
    private let monitor: NWPathMonitor

    private(set) var hasResponse = false
    private(set) var isConnected = false
    private(set) var isExpensive = false
    private(set) var currentConnectionType: NWInterface.InterfaceType?

    private init() {
        monitor = NWPathMonitor()
    }

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.hasResponse = true
            self?.isConnected = path.status != .unsatisfied
            self?.isExpensive = path.isExpensive
            self?.currentConnectionType = NWInterface.InterfaceType.allCases.filter { path.usesInterfaceType($0) }.first
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                for callback in self.callbacks {
                    callback.value(self)
                }
            }
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    var supportsDiscovery: Bool {
        return currentConnectionType == .wifi || currentConnectionType == .wiredEthernet || currentConnectionType == .other
    }

    func addListener(sender: NSObject, callback: @escaping Callback) {
        callbacks[sender] = callback
        if hasResponse {
            callback(self)
        }
    }

    func removeListener(sender: NSObject) {
        callbacks.removeValue(forKey: sender)
    }
}
