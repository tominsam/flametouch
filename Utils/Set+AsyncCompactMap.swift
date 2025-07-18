// Copyright 2015 Thomas Insam. All rights reserved.

import Foundation

/// Helper extension to add asyncCompactMap to Set since it is not available by default.
/// This allows asynchronous transformations with optional results, filtering out nils.
extension Set {
    func asyncCompactMap<T>(_ transform: (Element) async -> T?) async -> [T] {
        var results = [T]()
        for element in self {
            if let value = await transform(element) {
                results.append(value)
            }
        }
        return results
    }
}
