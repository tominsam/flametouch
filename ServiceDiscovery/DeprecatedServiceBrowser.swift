// Copyright 2015 Thomas Insam. All rights reserved.

import Foundation
import UIKit
import Utils

/// An implementation of ServiceBrowser that uses the deprecated NSNetService APIs
/// to discover and browse services.
class DeprecatedServiceBrowser: NSObject, ServiceBrowser {
    // Includes bluetooth, wifi direct, other domains, etc.
    // This currently has all sorts of tricky behavior with my Thread routers,
    // because all the thread bridges advertise everything on multiple domains,
    // so services show up more than once. I don't know if that's the right
    // behvavior right now.
    static let includePeerToPeer = false
    static let defaultDomain = includePeerToPeer ? "" : "local."

    weak var delegate: ServiceBrowserDelegate?

    /// meta-service browser, discovers more services
    private let metaServiceBrowser = configure(NetServiceBrowser()) {
        $0.includesPeerToPeer = includePeerToPeer
    }

    /// broadcast a service from the local device
    private let flameService = NetService(domain: DeprecatedServiceBrowser.defaultDomain, type: "_flametouch._tcp", name: UIDevice.current.name, port: 1812)

    /// lookup of service type to browser for this service type.
    private var netServiceBrowsers = [String: NetServiceBrowser]()

    /// definitive list of all services
    private var netServices = Set<NetService>()

    override init() {
        super.init()
        metaServiceBrowser.delegate = self
        flameService.delegate = self
    }

    private func broadcast() {
        let services = convertToServices(netServices)
        delegate?.serviceBrowser(self, didChangeServices: services)
    }

    /// start meta-browser and all service browsers
    func start() {
        ELog("Start")

        flameService.publish()

        metaServiceBrowser.searchForServices(ofType: "_services._dns-sd._udp.", inDomain: DeprecatedServiceBrowser.defaultDomain)
        for (serviceType, netServiceBrowser) in netServiceBrowsers {
            netServiceBrowser.searchForServices(ofType: serviceType, inDomain: DeprecatedServiceBrowser.defaultDomain)
        }
        broadcast()
    }

    /// stop the metabrowser and all service browsers
    func stop() {
        ELog("Stop")
        for service in netServices {
            service.stopMonitoring()
        }
        for (_, browser) in netServiceBrowsers {
            browser.delegate = nil
            browser.stop()
        }
        metaServiceBrowser.stop()
        flameService.stop()
        netServiceBrowsers.removeAll()
        broadcast()
    }

    func reset() {
        netServices.removeAll()
        broadcast()
    }

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
                alive: true
            )
        })
    }
}

// MARK: NetServiceBrowserDelegate

extension DeprecatedServiceBrowser: NetServiceBrowserDelegate {
    func netServiceBrowser(_: NetServiceBrowser, didFind service: NetService, moreComing _: Bool) {
        if service.type == "_tcp.local." || service.type == "_udp.local." {
            // meta-browser found something new. Create a new service browser for it.
            let serviceType = service.name + (service.type == "_tcp.local." ? "._tcp" : "._udp")
            ELog("✅ Found type \"\(serviceType)\"")
            if let found = netServiceBrowsers[serviceType] {
                ELog("stopping existing browser for \(serviceType)")
                found.stop()
            }

            let newBrowser = NetServiceBrowser()
            newBrowser.delegate = self
            newBrowser.searchForServices(ofType: serviceType, inDomain: DeprecatedServiceBrowser.defaultDomain)
            netServiceBrowsers[serviceType] = newBrowser

        } else {
            // single-service browser found a new broadcast
            ELog("🟡 Found service \(service.type)")

            // Services are not always cleaned up - for instance entering airplane mode won't remove services.
            netServices.insert(service)
            service.delegate = self
            service.resolve(withTimeout: 10)
            service.startMonitoring()
            broadcast()
        }
    }

    func netServiceBrowser(_: NetServiceBrowser, didRemove service: NetService, moreComing _: Bool) {
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
                ELog("‼️ can't remove service \(service.type)")
                return
            }
            service.stopMonitoring()
            netServices.remove(at: index)
        }
        broadcast()
    }

    func netServiceBrowser(_: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        ELog("Did not search: \(errorDict)")
    }
}

// MARK: NetServiceDelegate

extension DeprecatedServiceBrowser: NetServiceDelegate {
    func netServiceDidResolveAddress(_ service: NetService) {
        ELog("🟢 resolved \(service.type) \(service.name) \(service.domain) as \(service.stringAddresses)")
        broadcast()
    }

    func netService(_ service: NetService, didUpdateTXTRecord _: Data) {
        ELog("❕ New data for \(service.type) \(service.name)")
        broadcast()
    }

    func netServiceBrowser(_: NetServiceBrowser, didFindDomain domainString: String, moreComing _: Bool) {
        ELog("found domain \(domainString)")
    }

    func netServiceBrowser(_: NetServiceBrowser, didRemoveDomain domainString: String, moreComing _: Bool) {
        ELog("lost domain \(domainString)")
    }
}
