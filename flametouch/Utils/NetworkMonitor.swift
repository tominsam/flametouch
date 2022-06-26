// Copyright 2016 Thomas Insam. All rights reserved.

import Foundation
import Network
import RxSwift

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

    struct NetworkState {
        let hasResponse : Bool
        let isConnected : Bool
        let isExpensive : Bool
        let currentConnectionType: NWInterface.InterfaceType?

        var supportsDiscovery: Bool {
            return currentConnectionType == .wifi || currentConnectionType == .wiredEthernet || currentConnectionType == .other
        }
    }

    private let queue = DispatchQueue(label: "NetworkConnectivityMonitor")

    var state: Observable<NetworkState> { networkEvents.asObservable() }

    private init() {
    }

    var networkEvents: AsyncStream<NetworkState> {
        AsyncStream { continuation in
            let monitor = NWPathMonitor()

            monitor.pathUpdateHandler = { path in
                let state = NetworkState(
                    hasResponse: true,
                    isConnected: path.status != .unsatisfied,
                    isExpensive: path.isExpensive,
                    currentConnectionType: NWInterface.InterfaceType.allCases.filter { path.usesInterfaceType($0) }.first
                )
                continuation.yield(state)
            }
            continuation.onTermination = { _ in
                monitor.cancel()
            }
            monitor.start(queue: queue)
        }

    }

}
