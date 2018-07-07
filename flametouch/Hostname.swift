//
//  NetInfo.swift
//  flametouch
//
//  Created by tominsam on 2/21/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import UIKit

// Get the local ip addresses used by this node
func getIFAddress(_ data : Data) -> String? {

    //let hostname = [CChar](count: Int(INET6_ADDRSTRLEN), repeatedValue: 0)
    let hostname = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET6_ADDRSTRLEN))

	var _ = getnameinfo(
        (data as NSData).bytes.bindMemory(to: sockaddr.self, capacity: data.count), socklen_t(data.count),
        hostname, socklen_t(INET6_ADDRSTRLEN),
        nil, 0,
        NI_NUMERICHOST)

    let string = String(cString: hostname)

    // link local addresses don't cound
    if string.hasPrefix("fe80:") || string.hasPrefix("127.") {
        return nil
    }

    hostname.deinitialize(count: Int(INET6_ADDRSTRLEN))
    return string
}
