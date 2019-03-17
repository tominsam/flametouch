//
//  ELog.swift
//  Flame
//
//  Created by tominsam on 10/15/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import Foundation

func ELog(_ message : String) {
#if DEBUG
    NSLog(message)
#endif
//    CLSLogv(message, getVaList([]))
}

func ELog(_ message : String, _ args : CVarArg...) {
#if DEBUG
    NSLog(message, args)
#endif
//    CLSLogv(message, getVaList(args))
}

func ELogEvent(_ event: String, _ args: [String : Any]?) {
#if DEBUG
    NSLog(event + " %@", args ?? "nil")
#endif
//    Analytics.logEvent(event, parameters: args)
}
