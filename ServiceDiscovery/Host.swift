// Copyright 2021 Thomas Insam. All rights reserved.

import Foundation

public struct Host: Equatable, Hashable {
    public let services: Set<Service>

    public var address: String {
        return displayAddresses.first ?? "."
    }

    public var name: String {
        return ServiceNamer.nameForServices(services) ?? "Host"
    }

    public var subtitle: String {
        if services.count > 1 {
            return "\(address) (\(services.count) services)"
        } else {
            return "\(address) (One service)"
        }
    }

    var addresses: Set<String> {
        return services.reduce(Set<String>()) { addresses, service in
            addresses.union(service.addresses)
        }
    }

    public var displayAddresses: [String] {
        var addresses = Set<String>()
        var hostnames = Set<String>()
        for service in services {
            addresses.formUnion(service.addresses)
            if let hostname = service.hostname {
                hostnames.insert(hostname)
            }
        }

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
        for hostname in hostnames.sorted() {
            sortedAddresses.append(hostname)
        }

        return sortedAddresses
    }

    public var displayServices: [Service] {
        return services.sorted {
            if $0.type != $1.type {
                return $0.type < $1.type
            }
            if $0.domain != $1.domain {
                return $0.domain ?? "" < $1.domain ?? ""
            }
            return $0.name < $1.name
        }
    }

    public func matches(_ filter: String) -> Bool {
        if [name].contains(where: { $0.localizedCaseInsensitiveContains(filter) }) {
            return true
        }
        for service in services {
            if service.matches(filter) {
                return true
            }
        }
        return false
    }

    public func hasAnyAddress(_ addresses: Set<String>) -> Bool {
        return services.contains { $0.hasAnyAddress(addresses) }
    }
}

public extension Collection where Element == Host {
    func matching(addresses: Set<String>) -> Host? {
        return first { $0.hasAnyAddress(addresses) }
    }
}
