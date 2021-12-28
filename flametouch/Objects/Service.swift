// Copyright 2021 Thomas Insam. All rights reserved.

import Foundation

struct Service {

    // From the service itself
    let name: String
    let type: String
    let hostname: String?
    let addresses: Set<String>
    let port: Int
    let data: [String: String]

    // tracking data
    let lastSeen: Date
    var alive: Bool

    func matches(_ filter: String) -> Bool {
        if ([name, type, String(port), hostname ?? ""] + addresses).contains(where: { $0.localizedCaseInsensitiveContains(filter) }) {
            return true
        }
        for (key, value) in data {
            if key.localizedCaseInsensitiveContains(filter) || value.localizedCaseInsensitiveContains(filter) {
                return true
            }
        }
        return false
    }

    func hasAnyAddress(_ addresses: Set<String>) -> Bool {
        return !self.addresses.isDisjoint(with: addresses)
    }

    var displayAddresses: [String] {
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

    var url: URL? {
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

}

// Services are equivalent if they have the same name, type, port, and addresses
// (more strict than the spec but good enough for our needs.) This needs to be
// done instead of implicit struct equality because UDP services (eg thread)
// tend to resolve more than once.
extension Service: Equatable, Hashable {

    static func == (lhs: Service, rhs: Service) -> Bool {
        return lhs.name == rhs.name
        && lhs.type == rhs.type
        && lhs.port == rhs.port
        && lhs.addresses == rhs.addresses
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
        hasher.combine(self.type)
        hasher.combine(self.port)
        hasher.combine(self.addresses)
    }

}
