// Copyright 2021 Thomas Insam <tom@movieos.org>

import Foundation

// Wrap the observer weakly so that we don't retain anything.
private struct WeakObserver {
    weak var observer: ServiceControllerObserver?
}

// Remove all released observers
private extension Array where Element == WeakObserver {
    mutating func reap () {
        self = self.filter { nil != $0.observer }
    }
}

class ServiceControllerImpl: NSObject, ServiceController {

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
        ELog("Stopped for \(stoppedTime) (compared to \(ServiceControllerImpl.maxStopTime))")
        if stoppedTime > ServiceControllerImpl.maxStopTime {
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

    func observeServiceChanges(_ block: @escaping ([Host]) -> Void) -> ServiceControllerObserver {
        let observer = ServiceControllerObserver(block: block)
        let weakRef = WeakObserver(observer: observer)
        observers.append(weakRef)
        block(self.hosts)
        return observer
    }
}

extension ServiceControllerImpl: ServiceBrowserDelegate {

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
        hosts = groupServices(convertToServices(newServices))
        observers.reap()
        for weakObserver in observers {
            weakObserver.observer?.block(self.hosts)
        }
    }

}
