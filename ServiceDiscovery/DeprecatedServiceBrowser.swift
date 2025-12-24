// Copyright 2015 Thomas Insam. All rights reserved.

import Foundation
import UIKit

/// An implementation of ServiceBrowser that uses the deprecated NSNetService APIs
/// to discover and browse services. Ugly and doesn't use async/await because the underlying
/// APIs are pretty nasty in this respect and I have to abuse threads pretty badly to
/// walk the line of them working, but not blocking the main thread too badly.
class DeprecatedServiceBrowser: NSObject, ServiceBrowser {

    // We try to do all work on this queue
    let queue = DispatchQueue(label: "service browser", qos: .userInteractive)

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

    /// broadcast a service from the local device
    private var flameService: NetService?

    /// lookup of service type to browser for this service type.
    private var netServiceBrowsers = [String: NetServiceBrowser]()

    /// definitive list of all services (using a set here has been crashy)
    private var netServices = Array<NetService>()

    /// start meta-browser and all service browsers
    func start() {
        ELog("Starting")
        onQueue { [self] in
            // NetService and NetServiceBrowser must be constructed on the main thread or it doesn't work,
            // (and it'll also call its delegate methods on the main thread!)
            DispatchQueue.main.sync {
                flameService = NetService(
                    domain: Self.defaultDomain,
                    type: "_flametouch._tcp",
                    name: UIDevice.current.name,
                    port: 1812
                )
                flameService?.delegate = self
                flameService?.publish()

                metaServiceBrowser = NetServiceBrowser()
                metaServiceBrowser?.delegate = self
                metaServiceBrowser?.includesPeerToPeer = Self.includePeerToPeer

            }
            // This can be slow but is safe off the main thread
            metaServiceBrowser?.searchForServices(ofType: "_services._dns-sd._udp.", inDomain: Self.defaultDomain)
            for (serviceType, netServiceBrowser) in netServiceBrowsers {
                netServiceBrowser.searchForServices(ofType: serviceType, inDomain: Self.defaultDomain)
            }
            ELog("Started")
            broadcast()
        }
    }

    /// stop the metabrowser and all service browsers
    func pause(completion: @Sendable @escaping () -> Void) {
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
            flameService?.stop()
            netServiceBrowsers.removeAll()
            broadcast()
            ELog("Paused")
            DispatchQueue.main.sync {
                completion()
            }
        }
    }

    // full stop, unregister everything
    func stop(completion: @Sendable @escaping () -> Void) {
        ELog("Stop")
        pause() { [self] in
            onQueue { [self] in
                netServices.removeAll()
                AddressCluster.flushClusters()
                broadcast()
                DispatchQueue.main.sync {
                    completion()
                }
            }
        }
    }

    private func broadcast() {
        assert(!Thread.isMainThread)
        let services = convertToServices(netServices)
        DispatchQueue.main.sync {
            // Call the delegate method on the main thread because it's probably UI
            self.delegate?.serviceBrowser(self, didChangeServices: services)
        }
    }

    private func convertToServices(_ netServices: Array<NetService>) -> Set<Service> {
        assert(!Thread.isMainThread)
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
    func onQueue(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            queue.async(execute: block)
        } else {
            block()
        }
    }
}

// MARK: NetServiceBrowserDelegate
extension DeprecatedServiceBrowser: NetServiceBrowserDelegate {
    func netServiceBrowser(_: NetServiceBrowser, didFind service: NetService, moreComing _: Bool) {
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
            onQueue {
                // this is sometimes slow
                newBrowser.searchForServices(ofType: serviceType, inDomain: Self.defaultDomain)
            }

        } else {
            // single-service browser found a new broadcast
            // Services are not always cleaned up - for instance entering airplane mode won't remove services.
            if netServices.map(\.type).contains(service.type) {
                return
            }
            ELog("🟡 Found service \(service.type)")
            netServices.append(service)
            service.delegate = self
            onQueue { [self] in
                service.startMonitoring() // slow!
                service.resolve(withTimeout: 10) // slow!
                self.broadcast()
            }
        }

    }

    func netServiceBrowser(_: NetServiceBrowser, didRemove service: NetService, moreComing _: Bool) {
        onQueue { [self] in
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
    }

    func netServiceBrowser(_: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        ELog("Did not search: \(errorDict)")
    }
}


// MARK: NetServiceDelegate

extension DeprecatedServiceBrowser: NetServiceDelegate {
    func netServiceDidResolveAddress(_ service: NetService) {
        onQueue { [self] in
            ELog("🟢 resolved \(service.type) \(service.name) \(service.domain)")
            broadcast()
        }
    }

    func netService(_ service: NetService, didUpdateTXTRecord _: Data) {
        onQueue { [self] in
            //ELog("❕ New data for \(service.type) \(service.name)")
            broadcast()
        }
    }

    func netServiceBrowser(_: NetServiceBrowser, didFindDomain domainString: String, moreComing _: Bool) {
        ELog("found domain \(domainString)")
    }

    func netServiceBrowser(_: NetServiceBrowser, didRemoveDomain domainString: String, moreComing _: Bool) {
        ELog("lost domain \(domainString)")
    }
}
