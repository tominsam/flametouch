// Copyright 2021 Thomas Insam. All rights reserved.

import Foundation

public struct Host: Equatable, Hashable {
    public let services: Set<Service>
    public let addressCluster: AddressCluster

    public var name: String {
        return ServiceNamer.nameForServices(services) ?? "Host"
    }

    public var subtitle: String {
        if services.count > 1 {
            return "\(addressCluster.displayAddress) (\(services.count) services)"
        } else {
            return "\(addressCluster.displayAddress) (One service)"
        }
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

    public var alive: Bool {
        return !services.filter { $0.alive }.isEmpty
    }

    public func matches(search filter: String) -> Bool {
        if filter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        if [name].contains(where: { $0.localizedCaseInsensitiveContains(filter) }) {
            return true
        }
        for service in services {
            if service.matches(search: filter) {
                return true
            }
        }
        return false
    }

    public func isSameHost(as host: Host) -> Bool {
        return addressCluster == host.addressCluster
    }
}

public extension Collection where Element == Host {
    /// Returns optional Host object in the collection that is (probably) the same host as the passed host.
    func matching(host: Host) -> Host? {
        return first { $0.isSameHost(as: host) }
    }

    func serviceMatching(service: Service) -> Service? {
        let host = first { $0.addressCluster == service.addressCluster }
        return host?.services.first { $0.type == service.type && $0.name == service.name }
    }
}
