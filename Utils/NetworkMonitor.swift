// Copyright 2016 Thomas Insam. All rights reserved.

import Foundation
import Network

extension NWInterface.InterfaceType {
    static let allCases: [NWInterface.InterfaceType] = [
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

@Observable
public final class NetworkMonitor: Sendable {
    public struct NetworkState: Sendable {
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

    var state: NetworkState = .init(
        hasResponse: false,
        isConnected: true,
        isExpensive: false,
        currentConnectionType: nil
    )

    init() {
        ELog("Watching network state")
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            ELog("Network state changed")
            self?.state = NetworkState(
                hasResponse: true,
                isConnected: path.status != .unsatisfied,
                isExpensive: path.isExpensive,
                currentConnectionType: NWInterface.InterfaceType.allCases.filter(path.usesInterfaceType).first
            )
        }
        monitor.start(queue: Self.queue)
    }
}
