// Copyright 2016 Thomas Insam. All rights reserved.

import Combine
import Foundation
import Network

extension NWInterface.InterfaceType {
    static var allCases: [NWInterface.InterfaceType] = [
        .other,
        .wifi,
        .cellular,
        .loopback,
        .wiredEthernet,
    ]

    var supportsDiscovery: Bool {
        switch self {
        case .wifi, .wiredEthernet, .other, .loopback:
            return true
        case .cellular:
            return false
        @unknown default:
            return true
        }
    }
}

public final class NetworkMonitor {
    public struct NetworkState {
        public let hasResponse: Bool
        public let isConnected: Bool
        public let isExpensive: Bool
        public let currentConnectionType: NWInterface.InterfaceType?

        public var supportsDiscovery: Bool {
            currentConnectionType?.supportsDiscovery == true
        }
    }

    public static let shared = NetworkMonitor()

    private static let queue = DispatchQueue(label: "NetworkConnectivityMonitor")

    public var state: AnyPublisher<NetworkState, Never> {
        Deferred {
            ELog("Watching network state")
            let subject = PassthroughSubject<NetworkState, Never>()

            let monitor = NWPathMonitor()

            monitor.pathUpdateHandler = { path in
                ELog("Network state changed")
                let state = NetworkState(
                    hasResponse: true,
                    isConnected: path.status != .unsatisfied,
                    isExpensive: path.isExpensive,
                    currentConnectionType: NWInterface.InterfaceType.allCases.filter(path.usesInterfaceType).first
                )
                subject.send(state)
            }
            monitor.start(queue: Self.queue)
            return subject.handleEvents(receiveCancel: {
                ELog("Stopping network state watcher")
                monitor.cancel()
            })
        }.eraseToAnyPublisher()
    }
}
