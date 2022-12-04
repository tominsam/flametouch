// Copyright 2021 Thomas Insam. All rights reserved.

import Foundation

// Clustering addresses into hosts is the core Hard Problem of the whole app. Services can advertise multiple
// addresses, so the strategy is that any service that has >1 address will implicitly group those addresses
// into a host. Hosts can gain addresses and lose them, and services of that host might expose different subsets
// of the addresses of that host. But addresses come from DHCP so over the long term a given address might be
// re-used by a _different_ host. Finally, because we want to use UIDiffableDataSource, I want the identifier for
// a host to remain constant in the medium term. (I'm not going to worry about address re-assignment. I'm going to
// assume that any given IP is only ever going to be associated with a single host for the lifetime of the app)

// What happens if you roam between networks? Can I detect that? A perfect solution would be.. I guess resetting
// the clustering cache if the MAC address of my local network DHCP server changes? But as a fallback, manually
// refreshing the UI will reset the cluster cache and fix weirdness. (so pull-to-refresh or command-r)

// The absolute simplest reliable way of doing this is to remember every address we've ever seen,
// so this is a map from "every IP address we know about" to "the addresscluster instance for that IP"
var globalLookup = [String: AddressCluster]()

// An address cluster is a mutable instance with a random identifier (for diffing purposes)
// and a list of addresses and hostnames. The factory method takes a list of addresses,
// and vends the existing cluster that contains any of those addresses, adding them to the cluster,
// or creates a new cluster with those addresses.
public class AddressCluster {
    var identifier = UUID()

    var addresses: Set<String>
    var hostnames: Set<String>

    /// Return a new or existing address cluster for a given set of IP addresses. Any cluster that
    /// contains any of the provided addresses will be extended to contain all of the provided addresses
    /// (and hostnames) and returned, otherwise we'll create a new cluster.
    public static func from(addresses: any Collection<String>, hostnames: any Collection<String>) -> AddressCluster {
        // Look up the address in the global map
        var existing = Set(addresses.compactMap({ globalLookup[$0] }))
        if existing.isEmpty {
            existing.insert(AddressCluster(withAddresses: addresses, hostnames: hostnames))
        }
        // It's possible for the set of existing address clusters to have more than one element,
        // in the case where this new set of addresses corresponds to two previously separate clusters,
        // so it's required that we both synchronize all the addresses and hosts, but also the identifiers
        // so that they are considered equal (we want to retain the validity of the instances, though)
        let allAddresses = existing.flatMap { $0.addresses } + addresses
        let allHosts = existing.flatMap { $0.hostnames } + hostnames
        let primary = existing.first! // safe because we inserted a new cluster in this case

        for cluster in existing {
            cluster.add(addresses: allAddresses, hostnames: allHosts)
            cluster.identifier = primary.identifier
        }

        // Re-inject the primary cluster into the global map (the rest are still valid
        // in case someone is holding a reference to them
        for address in primary.addresses {
            globalLookup[address] = primary
        }

        return primary
    }

    /// Invalidates the lookup and starts afresh. Any held references to existing address
    /// clusters will no longer be valid!
    public static func flushClusters() {
        globalLookup.removeAll()
    }

    private init(withAddresses addresses: any Collection<String>, hostnames: any Collection<String>) {
        self.addresses = Set(addresses)
        self.hostnames = Set(hostnames)
    }

    private func add(addresses: any Collection<String>, hostnames: any Collection<String>) {
        self.addresses.formUnion(addresses)
        self.hostnames.formUnion(hostnames)
    }

    public var sorted: [String] {
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

    public var displayAddress: String {
        return sorted.first ?? "."
    }

    public var displayName: String? {
        return hostnames.sorted().first?.replacingOccurrences(of: ".local.", with: "")
    }
}

extension AddressCluster: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "<\(type(of: self)) \(addresses.sorted()) / \(hostnames.sorted()))>"
    }
}

extension AddressCluster: Hashable {
    public static func == (lhs: AddressCluster, rhs: AddressCluster) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
