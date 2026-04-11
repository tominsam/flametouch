// Copyright 2015 Thomas Insam. All rights reserved.
import Foundation
import UIKit

// MARK: - RunLoopExecutor

/// Custom SerialExecutor backed by a dedicated RunLoop thread. NSNetServiceBrowser
/// and NSNetService require a dedicated RunLoop — they cannot use the cooperative
/// thread pool. By making this the actor's executor, all actor state is automatically
/// accessed on the RunLoop thread with no manual dispatching needed.
final class RunLoopExecutor: SerialExecutor, @unchecked Sendable {
    fileprivate let runLoop: RunLoop
    let thread: Thread

    init() {
        nonisolated(unsafe)
        var capturedRunLoop: RunLoop?
        let semaphore = DispatchSemaphore(value: 0)
        thread = Thread {
            capturedRunLoop = RunLoop.current
            semaphore.signal()
            ELog("Starting runloop")
            RunLoop.current.add(NSMachPort(), forMode: .default)
            while true {
                let didProcess = RunLoop.current.run(mode: .default, before: .distantFuture)
                if !didProcess {
                    ELog("Nothing in runloop to process, snoozing")
                    Thread.sleep(forTimeInterval: 0.1)
                }
            }
        }
        thread.qualityOfService = .userInitiated
        thread.start()
        ELog("Waiting on runloop")
        semaphore.wait()
        ELog("Startup continues")
        self.runLoop = capturedRunLoop!
    }

    func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        runLoop.perform {
            job.runSynchronously(on: self.asUnownedSerialExecutor())
        }
    }

    func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    func checkIsolated() {
        precondition(Thread.current == thread, "Expected to be on RunLoop thread")
    }
}

// MARK: - DeprecatedServiceBrowser

/// An implementation of ServiceBrowser that uses the deprecated NSNetService APIs.
/// Uses a RunLoopExecutor as its actor executor so all state is accessed exclusively
/// on the RunLoop thread that NSNetServiceBrowser requires.
actor DeprecatedServiceBrowser: ServiceBrowser {

    // Includes bluetooth, wifi direct, other domains, etc.
    // This currently has all sorts of tricky behavior with my Thread routers,
    // because all the thread bridges advertise everything on multiple domains,
    // so services show up more than once. I don't know if that's the right
    // behavior right now.
    static let includePeerToPeer = false
    static let defaultDomain = includePeerToPeer ? "" : "local."

    nonisolated let services: AsyncStream<Set<Service>>
    private var continuation: AsyncStream<Set<Service>>.Continuation?

    private let executor: RunLoopExecutor

    // This forces the runloop as the thread for the actor
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        executor.asUnownedSerialExecutor()
    }

    // NSObject delegate shim, set on first start()
    private var delegateShim: NetServiceDelegateShim?

    /// meta-service browser, discovers more services
    private var metaServiceBrowser: NetServiceBrowser?
    /// lookup of service type to browser for this service type
    private var netServiceBrowsers = [String: NetServiceBrowser]()
    /// definitive list of all services (using a set here has been crashy)
    private var netServices = [NetService]()

    init() {
        executor = RunLoopExecutor()
        var cont: AsyncStream<Set<Service>>.Continuation?
        services = AsyncStream { cont = $0 }
        continuation = cont
    }

    /// start meta-browser and all service browsers
    func start() async {
        executor.checkIsolated()
        ELog("Starting")
        if delegateShim == nil { delegateShim = NetServiceDelegateShim(self) }
        metaServiceBrowser = NetServiceBrowser()
        metaServiceBrowser?.delegate = delegateShim
        metaServiceBrowser?.includesPeerToPeer = Self.includePeerToPeer
        metaServiceBrowser?.searchForServices(ofType: "_services._dns-sd._udp.", inDomain: Self.defaultDomain)
        for (serviceType, browser) in netServiceBrowsers {
            browser.searchForServices(ofType: serviceType, inDomain: Self.defaultDomain)
        }
        broadcast()
        ELog("Started")
    }

    /// stop the metabrowser and all service browsers
    func pause() async {
        executor.checkIsolated()
        ELog("Pausing")
        metaServiceBrowser?.stop()
        for service in netServices { service.stopMonitoring() }
        for (_, browser) in netServiceBrowsers {
            browser.delegate = nil
            browser.stop()
        }
        netServiceBrowsers.removeAll()
        broadcast()
        ELog("Paused")
    }

    /// full stop, unregister everything
    func stop() async {
        executor.checkIsolated()
        ELog("Stopping")
        await pause()
        netServices.removeAll()
        AddressCluster.flushClusters()
        broadcast()
        ELog("Stopped")
    }

    private func broadcast() {
        executor.checkIsolated()
        continuation?.yield(convertToServices(netServices))
    }

    private func convertToServices(_ netServices: [NetService]) -> Set<Service> {
        executor.checkIsolated()
        var services = [ServiceRef: Service]()
        for ns in netServices {
            let addresses = ns.stringAddresses // slow!
            if addresses.isEmpty { continue }
            if ns.hostName == "000000000000.local." {
                // All the eeros on my local network claim this address and
                // it's causing them to be clustered together.
                continue
            }
            let service = Service(
                name: ns.name,
                type: ns.type,
                domain: ns.domain == "local." ? nil : ns.domain,
                addressCluster: AddressCluster.from(
                    addresses: Set(addresses),
                    hostnames: Set([ns.hostName].compactMap { $0 })
                ),
                port: ns.port,
                data: ns.txtDict, // slow!
                lastSeen: Date(),
                alive: true
            )
            services[service.ref] = service
        }
        return Set(services.values)
    }

    // MARK: Called by NetServiceDelegateShim

    func didFind(service: NetService, inMetaBrowser: Bool) {
        executor.checkIsolated()
        if inMetaBrowser {
            let serviceType = service.name + (service.type == "_tcp.local." ? "._tcp" : "._udp")
            ELog("🟡 Found metaservice \(serviceType)")
            if let found = netServiceBrowsers[serviceType] {
                ELog("stopping existing browser for \(serviceType)")
                found.stop()
            }
            let newBrowser = NetServiceBrowser()
            newBrowser.delegate = delegateShim
            netServiceBrowsers[serviceType] = newBrowser
            newBrowser.searchForServices(ofType: serviceType, inDomain: Self.defaultDomain)
        } else {
            if netServices.contains(service) { return }
            ELog("🟡 Found service \(service.type)")
            netServices.append(service)
            service.delegate = delegateShim
            service.startMonitoring() // slow!
            service.resolve(withTimeout: 10) // slow!
            broadcast()
        }
    }

    func didRemove(service: NetService, inMetaBrowser: Bool) {
        executor.checkIsolated()
        if inMetaBrowser {
            let name = service.name + (service.type == "_tcp.local." ? "._tcp" : "._udp")
            ELog("🅾️ removed type \(name)")
            guard let browser = netServiceBrowsers[name] else {
                ELog("‼️ can't remove type \(service.name)")
                return
            }
            browser.stop()
            netServiceBrowsers.removeValue(forKey: name)
        } else {
            ELog("🔴 removed service \(service.type)")
            guard let index = netServices.firstIndex(of: service) else {
                ELog("‼️ can't remove service \(service.description)")
                return
            }
            service.stopMonitoring()
            netServices.remove(at: index)
        }
        broadcast()
    }

    func didResolveAddress(_ service: NetService) {
        executor.checkIsolated()
        ELog("🟢 resolved \(service.type) \(service.name) \(service.domain)")
        broadcast()
    }

    func didUpdateTXTRecord() {
        executor.checkIsolated()
        broadcast()
    }

    func didNotSearch(errorDict: [String: NSNumber]) {
        executor.checkIsolated()
        ELog("Did not search: \(errorDict)")
    }
}

// MARK: - NetServiceDelegateShim

/// NSObject subclass that receives ObjC delegate callbacks and forwards them to
/// DeprecatedServiceBrowser. Required because actors cannot inherit from NSObject.
/// Callbacks arrive on the RunLoop thread (same as the actor's executor), so
/// assumeIsolated is used for a direct synchronous call — no async hop needed.
private final class NetServiceDelegateShim: NSObject, NetServiceBrowserDelegate, NetServiceDelegate, Sendable {
    unowned let browser: DeprecatedServiceBrowser

    init(_ browser: DeprecatedServiceBrowser) {
        self.browser = browser
    }

    func netServiceBrowser(_: NetServiceBrowser, didFind service: NetService, moreComing _: Bool) {
        let isMetaBrowser = service.type == "_tcp.local." || service.type == "_udp.local."
        browser.assumeIsolated { $0.didFind(service: service, inMetaBrowser: isMetaBrowser) }
    }

    func netServiceBrowser(_: NetServiceBrowser, didRemove service: NetService, moreComing _: Bool) {
        let isMetaBrowser = service.type == "_tcp.local." || service.type == "_udp.local."
        browser.assumeIsolated { $0.didRemove(service: service, inMetaBrowser: isMetaBrowser) }
    }

    func netServiceBrowser(_: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        browser.assumeIsolated { $0.didNotSearch(errorDict: errorDict) }
    }

    func netServiceDidResolveAddress(_ service: NetService) {
        browser.assumeIsolated { $0.didResolveAddress(service) }
    }

    func netService(_: NetService, didUpdateTXTRecord _: Data) {
        browser.assumeIsolated { $0.didUpdateTXTRecord() }
    }

    func netServiceBrowser(_: NetServiceBrowser, didFindDomain domainString: String, moreComing _: Bool) {
        ELog("found domain \(domainString)")
    }

    func netServiceBrowser(_: NetServiceBrowser, didRemoveDomain domainString: String, moreComing _: Bool) {
        ELog("lost domain \(domainString)")
    }

    func netServiceDidPublish(_ sender: NetService) {
        ELog("Published \(sender.type)")
    }

    func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        ELog("failed to publish: \(errorDict)")
    }
}
