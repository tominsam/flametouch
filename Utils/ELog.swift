// Copyright 2016 Thomas Insam. All rights reserved.

import Foundation

public func ELog(_ message: String, fileName: String = #file) {
    #if DEBUG
        let file = fileName.split(separator: "/").last?.split(separator: ".").first ?? ""
        NSLog("%@", "[🔥][\(file)] \(message)")
    #endif
}
