// Copyright 2016 Thomas Insam. All rights reserved.

import Foundation

func ELog(_ message: String) {
    #if DEBUG
    NSLog("[ELog] %@", message)
    #endif
}
