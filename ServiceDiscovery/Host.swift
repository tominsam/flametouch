// Copyright 2021 Thomas Insam. All rights reserved.

import Foundation

public struct Host: Equatable, Hashable {
    public let services: Set<Service>
    public let addressCluster: AddressCluster

    public var name: String {
        ServiceNamer.nameForServices(services) ?? "Host"
    }

    public var subtitle: String {
        let countString = String(localized: "\(services.count, specifier: "%llu") service(s)")
        return "\(addressCluster.displayAddress) (\(countString))"
    }

    public var displayServices: [Service] {
        services.sorted {
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
        !services.filter(\.alive).isEmpty
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
        addressCluster == host.addressCluster
    }
}

public extension Collection where Element == Host {
    /// Returns optional Host object in the collection that is (probably) the same host as the passed host.
    func matching(host: Host) -> Host? {
        first { $0.isSameHost(as: host) }
    }

    func serviceMatching(service: Service) -> Service? {
        let host = first { $0.addressCluster == service.addressCluster }
        return host?.services.first { $0.type == service.type && $0.name == service.name }
    }
}
