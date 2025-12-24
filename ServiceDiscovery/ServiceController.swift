// Copyright 2021 Thomas Insam <tom@movieos.org>

import Combine
import Foundation

public protocol ServiceController {
    var clusters: CurrentValueSubject<[Host], Never> { get }
    func start() async
    func restart() async
    func stop() async

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
                clusters.value = []
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

    public func stop() async {
        await withCheckedContinuation { continuation in
            browser.pause() { [self] in
                stoppedDate = Date()
                continuation.resume()
            }
        }
    }

    /// Completely restart the controller, clear all caches, start from scratch
    public func restart() async {
        await withCheckedContinuation { continuation in
            browser.stop() { continuation.resume()
            }
        }
        clusters.value = []
        try? await Task.sleep(for: .seconds(0.5))
        await start()
    }

    public func host(for addressCluster: AddressCluster) -> Host? {
        clusters.value.first { $0.addressCluster == addressCluster }
    }
}

extension ServiceControllerImpl: ServiceBrowserDelegate {
    func serviceBrowser(_ serviceBrowser: ServiceBrowser, didChangeServices services: Set<Service>) {
        let hosts = groupServices(services)
        clusters.value = hosts
    }

    func groupServices(_ services: Set<Service>) -> [Host] {
        let oldClusters = clusters.value
            .flatMap(\.services)
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

public extension Publisher where Output == [Host] {
    func host(forAddressCluster addressCluster: AddressCluster) -> AnyPublisher<Host, Failure> {
        compactMap { hosts in
            hosts.first { $0.addressCluster == addressCluster }
        }.eraseToAnyPublisher()
    }
}
