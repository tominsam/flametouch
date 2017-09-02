//
//  ServiceName.swift
//  Flame
//
//  Created by tominsam on 9/15/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import Foundation

class ServiceName {

    // Ordered list of "important" service names - these will be used to extract the
    // host name preferentially
    static let IMPORTANT_NAMES = [
        "_airplay._tcp.",
        "_airport._tcp.",
        "_sleep-proxy._udp.",
        "_ssh._tcp.",
        "_ipp._tcp.", // printer
        "_googlecast._tcp.", // chromecast
    ]
    
    static func nameForServiceGroup(_ group : ServiceGroup) -> String {
        // Look for important names first
        for name in IMPORTANT_NAMES {
            for service in group.services {
                if service.type == "_googlecast._tcp." {
                    let map = mapFromService(service)
                    if let name = map["fn"] {
                        return name
                    } else {
                        return service.name
                    }
                    //return mapFromService(service)["fn"] ?? service.name
                } else if service.type == "_ipp._tcp." && service.name.contains(" @ ") {
                    // "printer name @ computer name" for windows printer sharing
                    return service.name.components(separatedBy: " @ ")[1]
                } else if service.type == name {
                    return service.name
                }
            }
        }
        // fallback
        return group.services.first!.name
    }

    static func mapFromService(_ service : NetService) -> [String: String] {
        var map = [String:String]()
        if let txtRecord = service.txtRecordData() {
            for (key, value) in NetService.dictionary(fromTXTRecord: txtRecord) {
                map[key] = String(bytes: value, encoding: .utf8)
            }
        }
        return map
    }

    
}
