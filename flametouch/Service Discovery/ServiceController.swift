// Copyright 2021 Thomas Insam <tom@movieos.org>

import Foundation

protocol ServiceController {
    var hosts: [Host] { get }
    func start()
    func stop()
    func restart()
    func observeServiceChanges(_ block: @escaping ([Host]) -> Void) -> ServiceControllerObserver
}

extension ServiceController {

    func hostFor(addresses: Set<String>) -> Host? {
        return hosts.first { $0.hasAnyAddress(addresses) }
    }

    func serviceFor(addresses: Set<String>, type: String, name: String) -> Service? {
        guard let host = hostFor(addresses: addresses) else { return nil }
        return host.services.first { $0.type == type && $0.name == name }
    }

    func groupServices(_ services: Set<Service>) -> [Host] {
        // Group the services by IP address - all services that share any address
        // are in a group, and a group is a "host".
        var groups = [Set<String>: Set<Service>]()

        for service in services {
            // If any address of this service is already in a group,
            // merge the service into the group, otherwise it's a new group
            if let element = groups.first(where: { service.hasAnyAddress($0.key) }) {
                let addresses = element.key.union(service.addresses)
                groups.removeValue(forKey: element.key)
                groups[addresses] = element.value.union([service])
            } else {
                groups[service.addresses] = [service]
            }
        }

        let hosts = groups.map { Host(services: $0.value) }

        return hosts.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

}

// Callers can observe changes. We hold them responsible for retaining
// the callback block, so it'll auto-cleanup. This is the observer object.
class ServiceControllerObserver: NSObject {
    let block: ([Host]) -> Void
    init(block : @escaping ([Host]) -> Void) {
        self.block = block
        super.init()
    }
}
