//
//  ServiceBrowser.swift
//  flametouch
//
//  Created by tominsam on 10/12/15.
//  Copyright © 2015 tominsam. All rights reserved.
//

import UIKit

class ServiceBrowser: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    /// meta-service browser, discovers more services
    let browser = NetServiceBrowser().configured {
        $0.includesPeerToPeer = true
    }

    /// broadcast a service from the local device
    let flameService = NetService(domain: "", type: "_flametouch._tcp", name: UIDevice.current.name, port: 1812)

    /// lookup of service type to browser for this service type.
	var browsers = [String: NetServiceBrowser]()

    /// definitive list of all services
    var services = Set<NetService>()

    /// list of sets of addresses assigned to a single machine
    var grouping = [Set<String>]()

    /// service display groups
    var serviceGroups = [ServiceGroup]()

    /// String filter to search the services
    var filter: String? {
        didSet { broadcast() }
    }

    override init() {
        super.init()
        browser.delegate = self
        flameService.delegate = self
    }

    /// start meta-browser and all service browsers
    func resume() {
        ELog("Resume")

        flameService.publish()

        browser.searchForServices(ofType: "_services._dns-sd._udp.", inDomain: "")
        for (service, b) in browsers {
            b.searchForServices(ofType: service, inDomain: "")
        }

        broadcast()
    }

    /// stop the metabrowser and all service browsers
    func pause() {
        ELog("Pause")
        browser.stop()
        for (_, b) in browsers {
            b.stop()
        }
        flameService.stop()
        // remove them, because the meta-browser is going to re-create everything.
        browsers.removeAll()
        services.removeAll()
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        if (service.type == "_tcp.local." || service.type == "_udp.local.") {
            // meta-browser found something new. Create a new service browser for it.
            let name = service.name + (service.type == "_tcp.local." ? "._tcp" : "._udp")
            ELog("Found type \"\(name)\"")
            if let found = browsers[name] {
                ELog("stopping existing browser (shouldn't really happen)")
                found.stop();
            }
            let newBrowser = NetServiceBrowser()
            newBrowser.delegate = self;

            newBrowser.searchForServices(ofType: name, inDomain: "")
            browsers[name] = newBrowser

        } else {
            // single-service browser found a new broadcast
            ELog("Found service " + service.type)

            // Services are not always cleaned up - for instance entering airplane mode won't remove services.
            // TODO detect this and clean them up.
            // But for now, at least don't leak duplicate service entries
            services.insert(service)
            service.delegate = self
            service.resolve(withTimeout: 10)
            broadcast()
        }
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        if (service.type == "_tcp.local." || service.type == "_udp.local.") {
            let name = service.name + (service.type == "_tcp.local." ? "._tcp" : "._udp")
            if let b = browsers[name] {
                b.stop()
                browsers.removeValue(forKey: name)
                ELog("removed type " + service.name)
            } else {
	            ELog("can't remove type " + service.name)
            }
        } else {
            if (services.contains(service)) {
        	    ELog("removed service " + service.type)
	        	services.remove(at: services.firstIndex(of: service)!)
                broadcast()
        	} else {
                ELog("can't remove service \(service.type)")
            }
        }
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        ELog("Did not search: \(errorDict)")
    }

    func netServiceDidResolveAddress(_ service: NetService) {
        ELog("resolved \(service)")
        broadcast()
	}

    func netService(_ service: NetService, didUpdateTXTRecord data: Data) {
        ELog("New data for \(service)")
        broadcast()
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
        ELog("found domain \(domainString)")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {
        ELog("lost domain \(domainString)")
    }



    func broadcast() {
        // alphabetize
        let services = Array(self.services).sorted {
            $0.type.lowercased().compare($1.type.lowercased()) == ComparisonResult.orderedAscending
        }

        grouping.removeAll()
        for service in services {
            let addresses = service.addresses!.compactMap { getIFAddress($0) }
            if var existingGroup = groupForAddresses(addresses) {
                existingGroup.formUnion(Set(addresses))
            } else {
                grouping.append(Set(addresses))
            }
        }

        var groups = [String: ServiceGroup]()
        for service in services {
            let addresses = service.addresses!.compactMap { getIFAddress($0) }
            if addresses.isEmpty {
                continue
            }
            if let group = groupForAddresses(addresses) {
                // shortest address - picks ipv4 first
                let ip = group.sorted {$0.count  < $1.count}.first!
                if let serviceGroup = groups[ip] {
                    serviceGroup.addService(service)
                    for address in group {
                        serviceGroup.addAddress(address)
                    }
                } else {
                    let serviceGroup = ServiceGroup(service: service, address: ip)
                    for address in group {
                        serviceGroup.addAddress(address)
                    }
                    groups[ip] = serviceGroup
                }
            } else {
             	precondition(false, "Can't happen")
            }
        }
        serviceGroups = groups.values.sorted { $0.title.lowercased() < $1.title.lowercased() }

        if let filter = filter {
            serviceGroups = serviceGroups.filter { $0.matches(filter) }
        }

        NotificationCenter.default.post(name: Notification.Name(rawValue: "ServicesChanged"), object: nil)
    }

    private func groupFor(_ address : String) -> Set<String>? {
	    for group in grouping {
            if group.contains(address) {
                return group
            }
    	}
        return nil
    }
    
    func serviceGroupFor(_ addresses : [String]) -> ServiceGroup? {
        for address in addresses {
            for group in serviceGroups {
                if group.addresses.contains(address) {
                    return group
                }
            }
        }
        return nil
    }

    func groupForAddresses(_ addresses : [String]) -> Set<String>? {
        for address in addresses {
            if let group = groupFor(address) {
                return group
            }
        }
        return nil
    }

}
