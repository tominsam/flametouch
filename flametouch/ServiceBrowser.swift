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
    /// lookup of service type to browser for this service type.
    var browsers = [NSNetService: NSNetServiceBrowser]()
    dynamic var services = Array<NSNetService>()

    override init() {
        super.init()
        browser.delegate = self
    }

    /// start meta-browser and all service browsers
    func resume() {
        NSLog("Resume")
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

    func netServiceBrowser(browser: NSNetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {}
    func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {}

    func broadcast() {
        // alphabetize
        services.sortInPlace({ (a, b) -> Bool in
            return a.name.lowercaseString.compare(b.name.lowercaseString) == NSComparisonResult.OrderedAscending
        })
        NSNotificationCenter.defaultCenter().postNotificationName("ServicesChanged", object: nil)
    }

}
