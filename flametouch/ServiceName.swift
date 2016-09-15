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
        "_ssh._udp.",
    ]
    
    static func nameForServiceGroup(_ group : ServiceGroup) -> String {
        // Look for important names first
        for name in IMPORTANT_NAMES {
            for service in group.services {
                if service.type == name {
                    return service.name
                }
            }
        }
        // fallback
        return group.services.first!.name
    }
    
}
