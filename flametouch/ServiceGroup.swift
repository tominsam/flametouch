//
//  ServiceGroup.swift
//  flametouch
//
//  Created by tominsam on 2/27/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import UIKit

class ServiceGroup: NSObject {

    var services = [NSNetService]()
    var addresses = [String]()

    init(service : NSNetService, address : String) {
        super.init()
        services.append(service)
        addresses.append(address)
    }

    func addService(service : NSNetService) {
        services.append(service)

        services.sortInPlace({ (a, b) -> Bool in
            return a.type.lowercaseString.compare(b.type.lowercaseString) == NSComparisonResult.OrderedAscending
        })
    }

    func addAddress(address : String) {
        if addresses.contains(address) {
            NSLog("already got %@ in %@", address, addresses)
            return
        }
        addresses.append(address)
        addresses.sortInPlace({ (a : String, b : String) -> Bool in
            return a.characters.count < b.characters.count
        })
        NSLog("addresses is \(addresses)")
    }

    var title : String {
        get {
            return services.first!.name
        }
    }

    var address : String {
        get {
            return addresses.first!
        }
    }

    var subTitle : String {
        get {
            if services.count > 1 {
                return "\(services.count) services (\(address))"
            } else {
                return "One service (\(address))"
            }
        }
    }

    override var description : String {
        get {
            return "<ServiceGroup \(title) \(addresses) (\(services))>"
        }
    }

}
