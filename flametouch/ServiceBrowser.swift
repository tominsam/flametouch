//
//  ServiceBrowser.swift
//  flametouch
//
//  Created by tominsam on 10/12/15.
//  Copyright © 2015 tominsam. All rights reserved.
//

import UIKit

class ServiceBrowser: NSObject, NSNetServiceBrowserDelegate, NSNetServiceDelegate {
    /// meta-service browser, discovers more services
    let browser = NSNetServiceBrowser()

    /// broadcast a service from the local device
    let flameService = NSNetService(domain: "", type: "_flametouch._tcp", name: UIDevice.currentDevice().name, port: 1812)

    /// lookup of service type to browser for this service type.
	var browsers = [NSNetService: NSNetServiceBrowser]()

    /// definitive list of all services
    var services = [NSNetService]()

    /// list of sets of addresses assigned to a single machine
    var grouping = [Set<String>]()

    /// service display groups
    var groups = [String: Array<NSNetService>]()

    override init() {
        super.init()
        browser.delegate = self
        flameService.delegate = self
    }

    /// start meta-browser and all service browsers
    func resume() {
        NSLog("Resume")

        flameService.publish()

        browser.searchForServicesOfType("_services._dns-sd._udp.", inDomain: "")
        for (service, b) in browsers {
            b.searchForServicesOfType(service.name, inDomain: service.domain)
        }

        broadcast()
    }

    /// stop the metabrowser and all service browsers
    func pause() {
        NSLog("Pause")
        browser.stop()
        for (_, b) in browsers {
            b.stop()
        }
        flameService.stop()
        // remove them, because the meta-browser is going to re-create everything.
        browsers.removeAll()
        services.removeAll()
    }

    func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool) {
        if (service.type == "_tcp.local." || service.type == "_udp.local.") {
            // meta-browser found something new. Create a new service browser for it.
            NSLog("Found type \"\(service.name)\" \"\(service.domain)\"")
            if let found = browsers[service] {
                NSLog("stopping existing browser (shouldn't really happen)")
                found.stop();
            }
            let newBrowser = NSNetServiceBrowser()
            newBrowser.delegate = self;

            let name = service.name + (service.type == "_tcp.local." ? "._tcp" : "._udp")
            newBrowser.searchForServicesOfType(name, inDomain: "")
            browsers[service] = newBrowser

        } else {
            // single-service browser found a new broadcast
            NSLog("Found service " + service.type)
            services.append(service)
            service.delegate = self
            service.resolveWithTimeout(10)
            broadcast()
        }
    }

    func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool) {
        if (service.type == "_tcp.local." || service.type == "_udp.local.") {
            if let b = browsers[service] {
                b.stop()
                browsers.removeValueForKey(service)
                NSLog("removed type " + service.name)
            } else {
	            NSLog("can't remove type " + service.name)
            }
        } else {
            if (services.contains(service)) {
        	    NSLog("removed service " + service.type)
	        	services.removeAtIndex(services.indexOf(service)!)
                broadcast()
        	} else {
                NSLog("can't remove service \(service.type)")
            }
        }
    }

    func netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        NSLog("Did not search: \(errorDict)")
    }

    func netServiceDidResolveAddress(service: NSNetService) {
        NSLog("resolved %@", service)
        broadcast()
	}

    func netService(service: NSNetService, didUpdateTXTRecordData data: NSData) {
        NSLog("New data for %@", service)
        broadcast()
    }

    func netServiceBrowser(browser: NSNetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
        NSLog("found domain %@", domainString)
    }

    func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {
        NSLog("lost domain %@", domainString)
    }



    func broadcast() {
        // alphabetize
        services.sortInPlace({ (a, b) -> Bool in
            return a.name.lowercaseString.compare(b.name.lowercaseString) == NSComparisonResult.OrderedAscending
        })

        grouping.removeAll()
        for service in services {
            let addresses = service.addresses!.flatMap({getIFAddress($0)})
            let group = groupForAddresses(addresses)
            if var hasGroup = group {
                _ = addresses.map({hasGroup.insert($0)})
            } else {
                grouping.append(Set(addresses))
            }
        }

        groups.removeAll()
        for service in services {
            let addresses = service.addresses!.flatMap({getIFAddress($0)})
            if addresses.isEmpty {
                continue
            }
            let group = groupForAddresses(addresses)
            if let hasGroup = group {
                // shortest address - picks ipv4 first
                let ip = hasGroup.sort({$0.characters.count > $1.characters.count}).first!
                if var serviceList = groups[ip] {
                    serviceList.append(service)
                    groups[ip] = serviceList
                } else {
                    groups[ip] = [service]
                }
            } else {
             	assert(false, "Can't happen")
            }
        }
        NSLog("groups is %@", groups)


        NSNotificationCenter.defaultCenter().postNotificationName("ServicesChanged", object: nil)
    }

    func groupFor(address : String) -> Set<String>? {
	    for group in grouping {
            if group.contains(address) {
                return group
            }
    	}
        return nil
    }

    func groupForAddresses(addresses : [String]) -> Set<String>? {
        for address in addresses {
            if let group = groupFor(address) {
                return group
            }
        }
        return nil
    }

}
