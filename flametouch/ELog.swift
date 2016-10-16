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
}
