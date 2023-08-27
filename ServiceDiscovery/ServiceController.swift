// Copyright 2021 Thomas Insam <tom@movieos.org>

import Foundation
import Utils
import Combine

public protocol ServiceController {
    var clusters: CurrentValueSubject<[Host], Never> { get }
    func start()
    func restart()
    func stop()

    func host(for addressCluster: AddressCluster) -> Host?
}

public class ServiceControllerImpl: NSObject, ServiceController {
    #if DEBUG
        private static let maxStopTime: TimeInterval = 10
    #else
        private static let maxStopTime: TimeInterval = 180
    #endif

    public var clusters = CurrentValueSubject<[Host], Never>([])

    private let browser: ServiceBrowser

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
            clusters.value = []
        }
        browser.start()
        self.stoppedDate = nil
    }

    public func stop() {
        browser.stop()
        stoppedDate = Date()
    }

    /// Completely restart the controller, clear all caches, start from scratch
    public func restart() {
        stop()
        browser.reset()
        clusters.value = []
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            start()
        }
    }

    public func host(for addressCluster: AddressCluster) -> Host? {
        return clusters.value.first { $0.addressCluster == addressCluster }
    }

}

extension ServiceControllerImpl: ServiceBrowserDelegate {
    func serviceBrowser(_: ServiceBrowser, didChangeServices services: Set<Service>) {
        let hosts = groupServices(services)
        self.clusters.value = hosts
    }

    func groupServices(_ services: Set<Service>) -> [Host] {
        let oldClusters = self.clusters.value
            .flatMap { $0.services }
            .map {
                var service = $0
                service.alive = false
                return service
            }

        // Collect services into hosts
        let groups = Dictionary(grouping: services + oldClusters, by: { $0.addressCluster })
        let hosts = groups.map { Host(services: Set($0.value), addressCluster: $0.key) }
        return hosts.sorted {
            ($0.name.lowercased(), $0.addressCluster.identifier.uuidString) < ($1.name.lowercased(), $1.addressCluster.identifier.uuidString)
        }
    }
}

extension Publisher where Output == [Host] {

    public func host(forAddressCluster addressCluster: AddressCluster) -> AnyPublisher<Host, Failure> {
        return self.compactMap { hosts in
            return hosts.first { $0.addressCluster == addressCluster }
        }.eraseToAnyPublisher()
    }

}
