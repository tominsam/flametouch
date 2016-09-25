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
import ReachabilitySwift

class WirelessDetect {
    
    let reachability = Reachability()!
    
    public var callback : ((Bool) -> Void)? = nil
    
    init() {
        reachability.whenReachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            DispatchQueue.main.async {
                print("Reachable")
                self.callback?(self.hasWireless())
            }
        }
        reachability.whenUnreachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            DispatchQueue.main.async {
                print("Not reachable")
                self.callback?(false)
            }
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
        
    }
    
    func hasWireless() -> Bool {
        
        guard let unwrappedCFArrayInterfaces = CNCopySupportedInterfaces() else {
            print("this must be a simulator, no interfaces found")
            return false
        }
        guard let swiftInterfaces = (unwrappedCFArrayInterfaces as NSArray) as? [NSString] else {
            print("System error: did not come back as array of Strings")
            return false
        }
        for interface in swiftInterfaces {
            print("Looking up SSID info for \(interface)") // en0
            guard let unwrappedCFDictionaryForInterface = CNCopyCurrentNetworkInfo(interface) else {
                print("System error: \(interface) has no information")
                return false
            }
            guard let SSIDDict = (unwrappedCFDictionaryForInterface as NSDictionary) as? [String: AnyObject] else {
                print("System error: interface information is not a string-keyed dictionary")
                return false
            }
            for d in SSIDDict.keys {
                print("\(d): \(SSIDDict[d]!)")
            }
        }
/*
        let callbackFunction : (SCNetworkReachability, SCNetworkReachabilityFlags, UnsafeMutableRawPointer?) -> Void {
            NSLog("Network changed")
        }
        let cfptr = CFunctionPointer<(SCNetworkReachability!, SCNetworkReachabilityFlags, UnsafeMutableRawPointer) -> Void>(cop)

        let reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, "www.apple.com")
        SCNetworkReachabilitySetCallback(reachability!, callbackFunction, nil)
*/
        return true
    }
}
