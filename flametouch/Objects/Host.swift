// Copyright 2021 Thomas Insam. All rights reserved.

import Foundation

struct Host: Equatable, Hashable {

    let services: Set<Service>

    var address: String {
        return displayAddresses.first ?? "."
    }

    var name: String {
        return ServiceNamer.nameForServices(services) ?? "Host"
    }

    var subtitle: String {
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

    var displayAddresses: [String] {
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

    var displayServices: [Service] {
        return services.sorted {
            ($0.type < $1.type)
            || ($0.domain ?? "" < $1.domain ?? "")
            || ($0.name < $1.name)
        }
    }

    func matches(_ filter: String) -> Bool {

        if ([name]).contains(where: { $0.localizedCaseInsensitiveContains(filter) }) {
            return true
        }
        for service in services {
            if service.matches(filter) {
                return true
            }
        }
        return false
    }

    func hasAnyAddress(_ addresses: Set<String>) -> Bool {
        return services.contains { $0.hasAnyAddress(addresses) }
    }
}
