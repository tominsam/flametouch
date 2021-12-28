// Copyright 2015 Thomas Insam. All rights reserved.

import Foundation
import UIKit

protocol ServiceBrowserDelegate: NSObjectProtocol {
    func serviceBrowser(_ serviceBrowser: ServiceBrowser, didChangeServices netServices: Set<NetService>)
}

class ServiceBrowser: NSObject {

    weak var delegate: ServiceBrowserDelegate?

    /// meta-service browser, discovers more services
    private let metaServiceBrowser = configure(NetServiceBrowser()) {
        // Don't look for bluetooth connections, never seen it work
        $0.includesPeerToPeer = true
    }

    /// broadcast a service from the local device
    private let flameService = NetService(domain: "", type: "_flametouch._tcp", name: UIDevice.current.name, port: 1812)

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
        delegate?.serviceBrowser(self, didChangeServices: netServices)
    }

    /// start meta-browser and all service browsers
    func start() {
        ELog("Resume")

        flameService.publish()

        metaServiceBrowser.searchForServices(ofType: "_services._dns-sd._udp.", inDomain: "")
        for (serviceType, netServiceBrowser) in netServiceBrowsers {
            netServiceBrowser.searchForServices(ofType: serviceType, inDomain: "")
        }
        broadcast()
    }

    /// stop the metabrowser and all service browsers
    func stop() {
        ELog("Pause")
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
}

// MARK: NetServiceBrowserDelegate
extension ServiceBrowser: NetServiceBrowserDelegate {

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
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
            newBrowser.searchForServices(ofType: serviceType, inDomain: "")
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

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
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

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        ELog("Did not search: \(errorDict)")
    }
}

// MARK: NetServiceDelegate
extension ServiceBrowser: NetServiceDelegate {

    func netServiceDidResolveAddress(_ service: NetService) {
        ELog("🟢 resolved \(service.type) \(service.name) \(service.domain) as \(service.stringAddresses)")
        broadcast()
    }

    func netService(_ service: NetService, didUpdateTXTRecord data: Data) {
        ELog("❕ New data for \(service.type) \(service.name)")
        broadcast()
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
        ELog("found domain \(domainString)")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {
        ELog("lost domain \(domainString)")
    }

}
