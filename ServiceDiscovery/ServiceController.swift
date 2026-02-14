// Copyright 2021 Thomas Insam <tom@movieos.org>

import Foundation

@MainActor
public protocol ServiceController: Observable {
    var clusters: [Host] { get }
    func start() async
    func restart() async
    func stop() async

    func host(for addressCluster: AddressCluster) -> Host?
}

@MainActor @Observable
public class ServiceControllerImpl: NSObject, ServiceController {
    /// If the browser is pasued (in background) for longer than this, hard-refresh because
    /// it's possibly a new environment. Otherwise soft-refresh, so we don't always resume
    /// to a blank screen.
    #if DEBUG
        private static let maxStopTime: TimeInterval = 10
    #else
        private static let maxStopTime: TimeInterval = 180
    #endif

    public var clusters: [Host] = []

    private let browser: ServiceBrowser

    private var stoppedDate: Date? = Date()

    @MainActor
    override convenience public init() {
        self.init(browser: DeprecatedServiceBrowser())
    }

    public static func demo() -> ServiceController {
        let controller = ServiceControllerImpl(browser: DemoServiceBrowser())
        Task {
            await controller.start()
        }
        return controller
    }

    internal init(browser: ServiceBrowser) {
        self.browser = browser
        super.init()
        self.browser.delegate = self
    }

    @MainActor
    public func start() async {
        // nil stoped date means we're running
        guard let stoppedDate = stoppedDate else { return }

        // If we were stopped for a while, reset all services,
        // otherwise we'll allow the old services list to persist
        // even though we restarted the browser
        let stoppedTime: TimeInterval = -stoppedDate.timeIntervalSinceNow
        ELog("Stopped for \(stoppedTime) (compared to \(ServiceControllerImpl.maxStopTime))")
        if stoppedTime > ServiceControllerImpl.maxStopTime {
            ELog("Resetting service list")
            browser.stop() { [self] in
                clusters = []
                browser.start()
                self.stoppedDate = nil
            }
        } else {
            ELog("Restarting service list")
            browser.pause() { [self] in
                browser.start()
                self.stoppedDate = nil
            }
        }
    }

    @MainActor
    public func stop() async {
        await withCheckedContinuation { continuation in
            browser.pause() { [self] in
                stoppedDate = Date()
                continuation.resume()
            }
        }
    }

    /// Completely restart the controller, clear all caches, start from scratch
    @MainActor
    public func restart() async {
        await withCheckedContinuation { continuation in
            browser.stop() { continuation.resume()
            }
        }
        clusters = []
        try? await Task.sleep(for: .seconds(0.5))
        await start()
    }

    public func host(for addressCluster: AddressCluster) -> Host? {
        clusters.first { $0.addressCluster == addressCluster }
    }
}

extension ServiceControllerImpl: ServiceBrowserDelegate {
    func serviceBrowser(didChangeServices services: Set<Service>) {
        dispatchPrecondition(condition: .onQueue(.main))
        Task {
            clusters = await Self.groupServices(oldClusters: clusters, services: services)
        }
    }

    @concurrent nonisolated
    static func groupServices(oldClusters: [Host], services: Set<Service>) async -> [Host] {
        dispatchPrecondition(condition: .notOnQueue(.main))

        // Collect services into hosts. We want to retain a service in the group for
        // every service and host we've ever seen, but mark them as no longer alive.
        // This means that if a service disappears it'll stay in the list but be rendered
        // as dead, but if it re-appears the same element will be marked as alive.

        // All services in the current list, with "alive" set to false
        let oldServices: [ServiceRef: [Service]] = oldClusters
            .flatMap(\.services)
            .map { $0.expire() }
            .groupBy(\.ref)

        // Filter to only the services _not_ in the new list
        let newRefs = Set(services.map(\.ref))
        let deadServices: [Service] = oldServices.filter { !newRefs.contains($0.key) }.values.flatMap { $0 }

        // Add the dead services to the new list - this is now all services, with only the missing
        // ones marked as dead.
        let allServices: Set<Service> = services.union(deadServices)

        // Group by addresscluster (which is a set of IP addresses we believe to belong to a
        // single specific machine) and convert to Hosts
        let hosts: [Host] = allServices.groupBy(\.addressCluster).map {
            Host(services: Set($0.value), addressCluster: $0.key)
        }

        // Sort by name and then my addresscluster (this sort must be deterministic)
        return hosts.sorted {
            ($0.name.lowercased(), $0.addressCluster.identifier.uuidString) < ($1.name.lowercased(), $1.addressCluster.identifier.uuidString)
        }
    }
}

extension Sequence {
    func groupBy<T: Hashable>(_ map: (Element) -> T) -> [T: [Element]]{
        Dictionary(grouping: self, by: map)
    }
}
