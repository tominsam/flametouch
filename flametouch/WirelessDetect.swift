//
//  WirelessDetect.swift
//  Flame
//
//  Created by tominsam on 9/15/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import Foundation
import SystemConfiguration

class WirelessDetect {
    
    static func hasWireless() -> Bool {
        let rechability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "www.apple.com")
        var flags : SCNetworkReachabilityFlags = SCNetworkReachabilityFlags()
        if SCNetworkReachabilityGetFlags(rechability!, &flags) == false {
            return false
        }
        return flags.contains(.isWWAN)
    }
}
