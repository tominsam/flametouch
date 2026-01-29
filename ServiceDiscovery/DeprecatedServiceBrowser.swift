// Copyright 2015 Thomas Insam. All rights reserved.
import os
import Foundation
import UIKit

/// An implementation of ServiceBrowser that uses the deprecated NSNetService APIs
/// to discover and browse services. Ugly and doesn't use async/await because the underlying
/// APIs are pretty nasty in this respect and I have to abuse threads pretty badly to
/// walk the line of them working, but not blocking the main thread too badly.
class DeprecatedServiceBrowser: NSObject, @MainActor ServiceBrowser, @unchecked Sendable {

    // NetServiceBrowser needs a runloop to work, but resolving addresses can block its thread. NSNetService can
    // only be interacted with on the runloop that it was created on, which is the runloop that NetServiceBrowser
    // is running on. So it's _critical_ that _all_ interactions with the low-level networking components are
    // on this background thread, which has its own dedicated runloop for the browser.
    var thread: Thread!
    var runLoop: RunLoop?

    // Includes bluetooth, wifi direct, other domains, etc.
    // This currently has all sorts of tricky behavior with my Thread routers,
    // because all the thread bridges advertise everything on multiple domains,
    // so services show up more than once. I don't know if that's the right
    // behvavior right now.
    static let includePeerToPeer = false
    static let defaultDomain = includePeerToPeer ? "" : "local."

    weak var delegate: ServiceBrowserDelegate?

    /// meta-service browser, discovers more services
    private var metaServiceBrowser: NetServiceBrowser?

    /// lookup of service type to browser for this service type.
    private var netServiceBrowsers = [String: NetServiceBrowser]()

    /// definitive list of all services (using a set here has been crashy)
    private var netServices = Array<NetService>()

    @MainActor
    override init() {
        super.init()

        // Block init (and so app startup!) until the NetService thread has at least assigned to self.runloop
        let semaphore = DispatchSemaphore(value: 0)

        thread = Thread { [self] in
            runLoop = RunLoop.current
            semaphore.signal()

            ELog("Starting runloop")
            // Add dummy source to keep runloop alive
            runLoop!.add(NSMachPort(), forMode: .default)
            while true {
                let didProcess = runLoop!.run(mode: .default, before: Date.distantFuture)
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
    }

    /// start meta-browser and all service browsers
    func start() {
        ELog("Starting")
        onQueue { [self] in

            metaServiceBrowser = NetServiceBrowser()
            metaServiceBrowser?.delegate = self
            metaServiceBrowser?.includesPeerToPeer = Self.includePeerToPeer

            // This can be slow
            metaServiceBrowser?.searchForServices(ofType: "_services._dns-sd._udp.", inDomain: Self.defaultDomain)
            for (serviceType, netServiceBrowser) in netServiceBrowsers {
                netServiceBrowser.searchForServices(ofType: serviceType, inDomain: Self.defaultDomain)
            }

            broadcast()
        } completion: {
            ELog("Started")
        }
    }

    /// stop the metabrowser and all service browsers
    func pause(completion: @MainActor @escaping () -> Void) {
        ELog("Pausing")
        onQueue { [self] in
            for service in netServices {
                service.stopMonitoring()
            }
            for (_, browser) in netServiceBrowsers {
                browser.delegate = nil
                browser.stop()
            }
            metaServiceBrowser?.stop()
            netServiceBrowsers.removeAll()
            broadcast()
        } completion: {
            ELog("Paused")
            completion()
        }
    }

    // full stop, unregister everything
    func stop(completion: @MainActor @escaping () -> Void) {
        dispatchPrecondition(condition: .onQueue(.main))
        ELog("Stopping")
        pause() { [self] in
            onQueue { [self] in
                netServices.removeAll()
                AddressCluster.flushClusters()
                broadcast()
            } completion: {
                ELog("Stopped")
                completion()
            }
        }
    }

    private func broadcast() {
        assert(Thread.current == self.thread)
        guard let delegate = self.delegate else { return }
        let services = convertToServices(netServices)
        DispatchQueue.main.sync {
            delegate.serviceBrowser(didChangeServices: services)
        }
    }

    private func convertToServices(_ netServices: Array<NetService>) -> Set<Service> {
        assert(Thread.current == self.thread)
        var services = Set<Service>()
        for ns in netServices {
            let addresses = ns.stringAddresses // slow!
            if addresses.isEmpty {
                // not resolved yet
                continue
            }
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
            services.insert(service)
        }
        return services
    }

    // Sanity utility - force main thread stuff on to the serial queue
    func onQueue(_ block: @Sendable @escaping () -> Void, completion: @MainActor @escaping () -> Void) {
        guard let runLoop else {
            fatalError("Runloop not started!!")
        }
        if Thread.current == self.thread {
            block()
            DispatchQueue.main.sync {
                completion()
            }
        } else {
            runLoop.perform {
                assert(Thread.current == self.thread)
                ELog("running")
                block()
                DispatchQueue.main.sync {
                    completion()
                }
            }
        }
    }
}

// MARK: NetServiceBrowserDelegate
extension DeprecatedServiceBrowser: NetServiceBrowserDelegate {
    func netServiceBrowser(_: NetServiceBrowser, didFind service: NetService, moreComing _: Bool) {
        assert(Thread.current == self.thread)
        if service.type == "_tcp.local." || service.type == "_udp.local." {
            // meta-browser found something new. Create a new service browser for it.
            let serviceType = service.name + (service.type == "_tcp.local." ? "._tcp" : "._udp")
            if netServiceBrowsers[serviceType] == nil {
                ELog("✅ Found type \"\(serviceType)\"")
            }
            if let found = netServiceBrowsers[serviceType] {
                ELog("stopping existing browser for \(serviceType)")
                found.stop()
            }

            // This must be on the main thread to work
            let newBrowser = NetServiceBrowser()
            newBrowser.delegate = self
            netServiceBrowsers[serviceType] = newBrowser
            newBrowser.searchForServices(ofType: serviceType, inDomain: Self.defaultDomain)

        } else {
            // single-service browser found a new broadcast
            // Services are not always cleaned up - for instance entering airplane mode won't remove services.
            if netServices.contains(service) {
                return
            }
            ELog("🟡 Found service \(service.type)")
            netServices.append(service)
            service.delegate = self
            service.startMonitoring() // slow!
            service.resolve(withTimeout: 10) // slow!
            self.broadcast()
        }

    }

    func netServiceBrowser(_: NetServiceBrowser, didRemove service: NetService, moreComing _: Bool) {
        assert(Thread.current == self.thread)
        if service.type == "_tcp.local." || service.type == "_udp.local." {
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

    func netServiceBrowser(_: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        assert(Thread.current == self.thread)
        ELog("Did not search: \(errorDict)")
    }
}


// MARK: NetServiceDelegate

extension DeprecatedServiceBrowser: NetServiceDelegate {
    func netServiceDidResolveAddress(_ service: NetService) {
        assert(Thread.current == self.thread)
        ELog("🟢 resolved \(service.type) \(service.name) \(service.domain)")
        broadcast()
    }

    func netService(_ service: NetService, didUpdateTXTRecord _: Data) {
        assert(Thread.current == self.thread)
        //ELog("❕ New data for \(service.type) \(service.name)")
        broadcast()
    }

    func netServiceBrowser(_: NetServiceBrowser, didFindDomain domainString: String, moreComing _: Bool) {
        assert(Thread.current == self.thread)
        ELog("found domain \(domainString)")
    }

    func netServiceBrowser(_: NetServiceBrowser, didRemoveDomain domainString: String, moreComing _: Bool) {
        assert(Thread.current == self.thread)
        ELog("lost domain \(domainString)")
    }

    func netServiceDidPublish(_ sender: NetService) {
        ELog("Published \(sender.type)")
    }

    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        ELog("failed to publish: \(errorDict)")
    }
}
