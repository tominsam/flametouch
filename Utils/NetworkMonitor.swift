// Copyright 2016 Thomas Insam. All rights reserved.

import Foundation
import Network
import Combine

// https://digitalbunker.dev/native-network-monitoring-in-swift/

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

    // MARK: - Public

    public static let shared = NetworkMonitor()

    public lazy var state = PassthroughSubject.emittingValues(from: networkEvents).eraseToAnyPublisher()

    // MARK: - Private

    private let queue = DispatchQueue(label: "NetworkConnectivityMonitor")

    private var networkEvents: AsyncStream<NetworkState> {
        AsyncStream { continuation in
            let monitor = NWPathMonitor()

            monitor.pathUpdateHandler = { path in
                let state = NetworkState(
                    hasResponse: true,
                    isConnected: path.status != .unsatisfied,
                    isExpensive: path.isExpensive,
                    currentConnectionType: NWInterface.InterfaceType.allCases.filter(path.usesInterfaceType).first
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
