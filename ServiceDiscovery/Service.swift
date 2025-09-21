// Copyright 2021 Thomas Insam. All rights reserved.

import Foundation

public struct Service: Sendable {
    // From the service itself
    public let name: String
    public let type: String
    public let domain: String?
    public let addressCluster: AddressCluster
    public let port: Int
    public let data: [String: String]

    // tracking data
    public let lastSeen: Date
    public var alive: Bool

    public func matches(search filter: String) -> Bool {
        if ([name, type, domain ?? "", String(port)] + addressCluster.sorted).contains(where: { $0.localizedCaseInsensitiveContains(filter) }) {
            return true
        }
        for (key, value) in data {
            if key.localizedCaseInsensitiveContains(filter) || value.localizedCaseInsensitiveContains(filter) {
                return true
            }
        }
        return false
    }

    public var url: URL? {
        switch type.split(separator: ".").first {
        case "_http":
            return URL(string: "http://\(addressCluster.displayAddress):\(port)/")
        case "_https":
            return URL(string: "https://\(addressCluster.displayAddress):\(port)/")
        case "_ssh":
            return URL(string: "ssh://\(addressCluster.displayAddress):\(port)/")
        case "_smb":
            return URL(string: "smb://\(addressCluster.displayAddress):\(port)/")
        case "_sonos":
            return URL(string: "http://\(addressCluster.displayAddress):1400/support/review")
        default:
            return nil
        }
    }

    public var openAction: String {
        switch type.split(separator: ".").first {
        case "_http":
            return "Open web page"
        case "_https":
            return "Open web page"
        case "_ssh":
            return "Connect to SSH server"
        case "_smb":
            return "Connect to file server"
        case "_sonos":
            return "See Sonos status"
        default:
            return "Open \(type.split(separator: ".").first, default: type) service"
        }
    }

    public var typeWithDomain: String {
        if let domain = domain {
            return "\(type) (\(domain))"
        } else {
            return type
        }
    }
}

// Services are equivalent if they have the same name, type, port, and addresses
// (more strict than the spec but good enough for our needs.) This needs to be
// done instead of implicit struct equality because UDP services (eg thread)
// tend to resolve more than once.
extension Service: @MainActor Equatable, @MainActor Hashable, Identifiable {
    public static func == (lhs: Service, rhs: Service) -> Bool {
        lhs.name == rhs.name
            && lhs.type == rhs.type
            && lhs.domain == rhs.domain
            && lhs.port == rhs.port
            && lhs.addressCluster == rhs.addressCluster
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(type)
        hasher.combine(domain)
        hasher.combine(port)
        hasher.combine(addressCluster)
    }

    public var id: Service {
        self
    }
}
