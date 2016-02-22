//
//  NetInfo.swift
//  flametouch
//
//  Created by tominsam on 2/21/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import UIKit

// Get the local ip addresses used by this node
func getIFAddress(data : NSData) -> String? {

    //let hostname = [CChar](count: Int(INET6_ADDRSTRLEN), repeatedValue: 0)
    let hostname = UnsafeMutablePointer<Int8>.alloc(Int(INET6_ADDRSTRLEN))

	var _ = getnameinfo(
        UnsafePointer(data.bytes), socklen_t(data.length),
        hostname, socklen_t(INET6_ADDRSTRLEN),
        nil, 0,
        NI_NUMERICHOST)

    let string = String.fromCString(hostname)!

    // link local addresses don't cound
    if string.hasPrefix("fe80:") || string.hasPrefix("127.") {
        return nil
    }

    hostname.destroy()
    return string
}
