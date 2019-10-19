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
    let browser = NetServiceBrowser()

    /// broadcast a service from the local device
    let flameService = NetService(domain: "", type: "_flametouch._tcp", name: UIDevice.current.name, port: 1812)

    /// lookup of service type to browser for this service type.
	var browsers = [NetService: NetServiceBrowser]()

    /// definitive list of all services
    var services = [NetService]()

    /// list of sets of addresses assigned to a single machine
    var grouping = [Set<String>]()

    /// service display groups
    var serviceGroups = [ServiceGroup]()

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
            b.searchForServices(ofType: service.name, inDomain: service.domain)
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
            ELog("Found type \"\(service.name)\" \"\(service.domain)\"")
            if let found = browsers[service] {
                ELog("stopping existing browser (shouldn't really happen)")
                found.stop();
            }
            let newBrowser = NetServiceBrowser()
            newBrowser.delegate = self;

            let name = service.name + (service.type == "_tcp.local." ? "._tcp" : "._udp")
            newBrowser.searchForServices(ofType: name, inDomain: "")
            browsers[service] = newBrowser

        } else {
            // single-service browser found a new broadcast
            ELog("Found service " + service.type)
            services.append(service)
            service.delegate = self
            service.resolve(withTimeout: 10)
            broadcast()
        }
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        if (service.type == "_tcp.local." || service.type == "_udp.local.") {
            if let b = browsers[service] {
                b.stop()
                browsers.removeValue(forKey: service)
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
        services.sort {
            return $0.type.lowercased().compare($1.type.lowercased()) == ComparisonResult.orderedAscending
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
