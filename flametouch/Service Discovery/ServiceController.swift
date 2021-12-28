// Copyright 2021 Thomas Insam <tom@movieos.org>

import Foundation

// Callers can observe changes. We hold them responsible for retaining
// the callback block, so it'll auto-cleanup. This is the observer object.
class ServiceControllerObserver: NSObject {
    let block: ([Host]) -> Void
    init(block : @escaping ([Host]) -> Void) {
        self.block = block
        super.init()
    }
}

// Wrap the observer weakly so that we don't retain anything.
struct WeakObserver {
    weak var observer: ServiceControllerObserver?
}

// Remove all released observers
extension Array where Element == WeakObserver {
    mutating func reap () {
        self = self.filter { nil != $0.observer }
    }
}

class ServiceController: NSObject {

    private let browser: ServiceBrowser

    private var observers = [WeakObserver]()

    private var stoppedDate: Date? = Date()

    #if DEBUG
    static let maxStopTime: TimeInterval = 10
    #else
    static let maxStopTime: TimeInterval = 180
    #endif

    /// list of sets of addresses assigned to a single machine
    var hosts = [Host]()

    override init() {
        browser = ServiceBrowser()
        super.init()
        browser.delegate = self
    }

    func start() {
        // nil stoped date means we're running
        guard let stoppedDate = stoppedDate else { return }

        // If we were stopped for a while, reset all services,
        // otherwise we'll allow the old services list to persist
        // even though we restarted the browser
        let stoppedTime: TimeInterval = -stoppedDate.timeIntervalSinceNow
        ELog("Stopped for \(stoppedTime) (compared to \(ServiceController.maxStopTime))")
        if stoppedTime > ServiceController.maxStopTime {
            ELog("Resetting service list")
            browser.reset()
        }
        browser.start()
        self.stoppedDate = nil
    }

    func stop() {
        browser.stop()
        stoppedDate = Date()
    }

    func restart() {
        stop()
        browser.reset()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.start()
        }
    }

    func hostFor(addresses: Set<String>) -> Host? {
        return hosts.first { $0.hasAnyAddress(addresses) }
    }

    func serviceFor(addresses: Set<String>, type: String, name: String) -> Service? {
        guard let host = hostFor(addresses: addresses) else { return nil }
        return host.services.first { $0.type == type && $0.name == name }
    }

    func observeServiceChanges(_ block: @escaping ([Host]) -> Void) -> ServiceControllerObserver {
        let observer = ServiceControllerObserver(block: block)
        let weakRef = WeakObserver(observer: observer)
        observers.append(weakRef)
        block(self.hosts)
        return observer
    }
}

extension ServiceController: ServiceBrowserDelegate {

    private func convertToServices(_ netServices: Set<NetService>) -> Set<Service> {
        return Set(netServices.compactMap { ns -> Service? in
            if ns.stringAddresses.isEmpty {
                // not resolved yet
                return nil
            }
            return Service(
                name: ns.name,
                type: ns.type,
                domain: ns.domain == "local." ? nil : ns.domain,
                hostname: ns.hostName,
                addresses: ns.stringAddresses,
                port: ns.port,
                data: ns.txtDict,
                lastSeen: Date(),
                alive: true)
        })
    }

    func serviceBrowser(_ serviceBrowser: ServiceBrowser, didChangeServices newServices: Set<NetService>) {

        let services = convertToServices(newServices)

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

        self.hosts = hosts.sorted { $0.name.lowercased() < $1.name.lowercased() }

        observers.reap()
        for weakObserver in observers {
            weakObserver.observer?.block(self.hosts)
        }
    }

}
