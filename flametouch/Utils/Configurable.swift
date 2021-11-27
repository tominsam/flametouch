// Copyright 2019 Thomas Insam. All rights reserved.

import Foundation

public func configure<T>(_ thing: T, _ block: (T) -> Void) -> T {
    block(thing)
    return thing
}
