//
//  ServiceGroup.swift
//  flametouch
//
//  Created by tominsam on 2/27/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import UIKit

class ServiceGroup: NSObject {

    var services = [NetService]()
    var addresses = [String]()

    init(service : NetService, address : String) {
        super.init()
        services.append(service)
        addresses.append(address)
    }

    func addService(_ service : NetService) {
        services.append(service)

        services.sort(by: { (a, b) -> Bool in
            return a.type.lowercased().compare(b.type.lowercased()) == ComparisonResult.orderedAscending
        })
    }

    func addAddress(_ address : String) {
        if addresses.contains(address) {
            NSLog("already got %@ in %@", address, addresses)
            return
        }
        addresses.append(address)
        addresses.sort(by: { (a : String, b : String) -> Bool in
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
                return "\(address) (\(services.count) services)"
            } else {
                return "\(address) (One service)"
            }
        }
    }

    override var description : String {
        get {
            return "<ServiceGroup \(title) \(addresses) (\(services))>"
        }
    }

}
