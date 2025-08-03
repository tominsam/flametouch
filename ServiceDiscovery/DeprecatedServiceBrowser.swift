// Copyright 2015 Thomas Insam. All rights reserved.

import Foundation
import UIKit

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
    private let metaServiceBrowser = with(NetServiceBrowser()) {
        $0.includesPeerToPeer = includePeerToPeer
    }

    /// broadcast a service from the local device
    private var flameService: NetService?

    /// lookup of service type to browser for this service type.
    private var netServiceBrowsers = [String: NetServiceBrowser]()

    /// definitive list of all services
    private var netServices = Set<NetService>()

    override init() {
        super.init()
        metaServiceBrowser.delegate = self
    }

    private func broadcast() async {
        let services = await convertToServices(netServices)
        await delegate?.serviceBrowser(self, didChangeServices: services)
    }

    /// start meta-browser and all service browsers
    func start() async {
        ELog("Start")

        flameService = NetService(
            domain: DeprecatedServiceBrowser.defaultDomain,
            type: "_flametouch._tcp",
            name: UIDevice.current.name,
            port: 1812
        )
        flameService?.delegate = self
        flameService?.publish()

        metaServiceBrowser.searchForServices(ofType: "_services._dns-sd._udp.", inDomain: DeprecatedServiceBrowser.defaultDomain)
        for (serviceType, netServiceBrowser) in netServiceBrowsers {
            netServiceBrowser.searchForServices(ofType: serviceType, inDomain: DeprecatedServiceBrowser.defaultDomain)
        }
        await broadcast()
    }

    /// stop the metabrowser and all service browsers
    func stop() async {
        ELog("Stop")
        for service in netServices {
            service.stopMonitoring()
        }
        for (_, browser) in netServiceBrowsers {
            browser.delegate = nil
            browser.stop()
        }
        metaServiceBrowser.stop()
        flameService?.stop()
        netServiceBrowsers.removeAll()
        await broadcast()
    }

    func reset() async {
        await stop()
        netServices.removeAll()
        AddressCluster.flushClusters()
        await broadcast()
    }

    private func convertToServices(_ netServices: Set<NetService>) async -> Set<Service> {
        var services = Set<Service>()
        for ns in netServices {
            let addresses = await ns.stringAddresses
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
                data: ns.txtDict,
                lastSeen: Date(),
                alive: true
            )
            services.insert(service)
        }
        return services
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

            let newBrowser = NetServiceBrowser()
            newBrowser.delegate = self
            DispatchQueue.global().async {
                newBrowser.searchForServices(ofType: serviceType, inDomain: DeprecatedServiceBrowser.defaultDomain)
            }
            netServiceBrowsers[serviceType] = newBrowser

        } else {
            // single-service browser found a new broadcast
            if !netServices.contains(service) {
                ELog("🟡 Found service \(service.type)")
            }

            // Services are not always cleaned up - for instance entering airplane mode won't remove services.
            netServices.insert(service)
            service.delegate = self
            service.startMonitoring()
            DispatchQueue.global().async {
                service.resolve(withTimeout: 10)
            }
            Task { await self.broadcast() }
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
        Task { await self.broadcast() }
    }

    func netServiceBrowser(_: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        ELog("Did not search: \(errorDict)")
    }
}

// MARK: NetServiceDelegate

extension DeprecatedServiceBrowser: NetServiceDelegate {
    func netServiceDidResolveAddress(_ service: NetService) {
        ELog("🟢 resolved \(service.type) \(service.name) \(service.domain)")
        Task { await self.broadcast() }
    }

    func netService(_ service: NetService, didUpdateTXTRecord _: Data) {
        ELog("❕ New data for \(service.type) \(service.name)")
        Task { await self.broadcast() }
    }

    func netServiceBrowser(_: NetServiceBrowser, didFindDomain domainString: String, moreComing _: Bool) {
        ELog("found domain \(domainString)")
    }

    func netServiceBrowser(_: NetServiceBrowser, didRemoveDomain domainString: String, moreComing _: Bool) {
        ELog("lost domain \(domainString)")
    }
}
