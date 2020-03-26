//
//  WirelessDetect.swift
//  Flame
//
//  Created by tominsam on 9/15/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import Foundation
import SystemConfiguration
import SystemConfiguration.CaptiveNetwork
import aiReachability

class WirelessDetect {
    
    let reachability = NetworkMonitor()
    
    public var callback : ((Bool) -> Void)? = nil
    
    init() {
        reachability.networkUpdateHandler = { [weak self] status in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            DispatchQueue.main.async {
                ELog("Reachable \(String(describing: self?.reachability.wifiState))")
                self?.callback?(self?.reachability.wifiState == .connected)
            }
        }
        ELog("Startup Reachable \(String(describing: reachability.wifiState))")
        self.callback?(reachability.wifiState == .connected)
        }
    
}
