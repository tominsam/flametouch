// Copyright 2021 Thomas Insam <tom@movieos.org>

import Foundation
import RxSwift
import Utils

public protocol ServiceController {
    var hosts: [Host] { get }
    var services: Observable<[Host]> { get }
    func start()
    func restart()
    func stop()
}

public class ServiceControllerImpl: NSObject, ServiceController {
    #if DEBUG
        private static let maxStopTime: TimeInterval = 10
    #else
        private static let maxStopTime: TimeInterval = 180
    #endif

    public var services: Observable<[Host]> { servicesSubject.asObservable().distinctUntilChanged() }
    public var hosts = [Host]() {
        didSet {
            servicesSubject.onNext(hosts)
        }
    }

    private let browser: ServiceBrowser
    private let servicesSubject = PublishSubject<[Host]>()

    private var stoppedDate: Date? = Date()

    override public init() {
        browser = DeprecatedServiceBrowser()
        super.init()
        browser.delegate = self
    }

    public func start() {
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

    public func stop() {
        browser.stop()
        stoppedDate = Date()
    }

    public func restart() {
        stop()
        browser.reset()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.start()
        }
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

extension ServiceControllerImpl: ServiceBrowserDelegate {
    func serviceBrowser(_: ServiceBrowser, didChangeServices services: Set<Service>) {
        hosts = groupServices(services)
    }
}
