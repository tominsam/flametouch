// Copyright 2021 Thomas Insam. All rights reserved.

import Foundation

public struct Service {
    // From the service itself
    public let name: String
    public let type: String
    public let domain: String?
    public let hostname: String?
    public let addresses: Set<String>
    public let port: Int
    public let data: [String: String]

    // tracking data
    public let lastSeen: Date
    public var alive: Bool

    public func matches(_ filter: String) -> Bool {
        if ([name, type, domain ?? "", String(port), hostname ?? ""] + addresses).contains(where: { $0.localizedCaseInsensitiveContains(filter) }) {
            return true
        }
        for (key, value) in data {
            if key.localizedCaseInsensitiveContains(filter) || value.localizedCaseInsensitiveContains(filter) {
                return true
            }
        }
        return false
    }

    public func hasAnyAddress(_ addresses: Set<String>) -> Bool {
        return !self.addresses.isDisjoint(with: addresses)
    }

    public var displayAddresses: [String] {
        // Sort service addresses by shortest first, so we prioritize IPv4
        var sortedAddresses = addresses.sorted {
            // Sort by length then alpha
            if $0.count == $1.count {
                return $0 < $1
            } else {
                return $0.count < $1.count
            }
        }

        // If the service claims a resolved hostname, include that at the end
        // (because often the hostname is not interesting as an address)
        if let hostname = hostname {
            sortedAddresses.append(hostname)
        }

        return sortedAddresses
    }

    public var url: URL? {
        switch type.split(separator: ".").first {
        case "_http":
            return URL(string: "http://\(displayAddresses[0]):\(port)/")
        case "_https":
            return URL(string: "https://\(displayAddresses[0]):\(port)/")
        case "_ssh":
            return URL(string: "ssh://\(displayAddresses[0]):\(port)/")
        case "_smb":
            return URL(string: "smb://\(displayAddresses[0]):\(port)/")
        default:
            return nil
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
extension Service: Equatable, Hashable {
    public static func == (lhs: Service, rhs: Service) -> Bool {
        return lhs.name == rhs.name
            && lhs.type == rhs.type
            && lhs.domain == rhs.domain
            && lhs.port == rhs.port
            && lhs.addresses == rhs.addresses
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(type)
        hasher.combine(domain)
        hasher.combine(port)
        hasher.combine(addresses)
    }
}

public extension Collection where Element == Service {
    func matching(service: Service) -> Service? {
        return first { $0.type == service.type && $0.name == service.name }
    }
}
