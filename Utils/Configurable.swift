// Copyright 2019 Thomas Insam. All rights reserved.

import Foundation

nonisolated public func with<T>(_ thing: T, _ block: (T) -> Void) -> T {
    block(thing)
    return thing
}
