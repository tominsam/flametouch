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
        sortServices()
        addresses.append(address)
        sortAddresses()
    }

    func addService(_ service : NetService) {
        services.append(service)
        sortServices()
    }

    private func sortServices() {
        services.sort { $0.type.lowercased() < $1.type.lowercased() }
    }

    func addAddress(_ address : String) {
        if addresses.contains(address) {
            return
        }
        addresses.append(address)
        sortAddresses()
    }

    private func sortAddresses() {
        addresses.sort {
            // Sort by length then alpha
            if $0.count == $1.count {
                return $0 < $1
            } else {
                return $0.count < $1.count
            }
        }
    }

    var title: String {
        get {
            return ServiceName.nameForServiceGroup(self)
        }
    }

    var address: String {
        get {
            return addresses.first ?? "."
        }
    }

    var subTitle: String {
        get {
            if services.count > 1 {
                return "\(address) (\(services.count) services)"
            } else {
                return "\(address) (One service)"
            }
        }
    }

    override var description: String {
        get {
            return "<ServiceGroup \(title) \(addresses) (\(services))>"
        }
    }

    func matches(_ filter: String) -> Bool {
        if title.localizedCaseInsensitiveContains(filter) || subTitle.localizedCaseInsensitiveContains(filter) || address.localizedCaseInsensitiveContains(filter) {
            return true
        }
        for service in services {
            if service.name.localizedCaseInsensitiveContains(filter) || service.type.localizedCaseInsensitiveContains(filter) {
                return true
            }
            for (key, value) in service.txtData {
                if key.localizedCaseInsensitiveContains(filter) || value.localizedCaseInsensitiveContains(filter) {
                    return true
                }
            }
        }
        return false
    }

}
