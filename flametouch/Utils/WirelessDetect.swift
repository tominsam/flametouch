// Copyright 2016 Thomas Insam. All rights reserved.

import Foundation
import aiReachability

class WirelessDetect {

    let reachability = NetworkMonitor()

    public var callback: ((Bool) -> Void)?

    init() {
        reachability.networkUpdateHandler = { [weak self] _ in
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
