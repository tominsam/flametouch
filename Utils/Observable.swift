// Copyright 2024 Thomas Insam. All rights reserved.

import Foundation

public func observeObject<T: Observable & AnyObject, S>(_ object: T, keypath: KeyPath<T, S>, onChange: @escaping (S) -> Void) {
    withObservationTracking {
        _ = object[keyPath: keypath]
    } onChange: { [weak object] in
        guard let object else { return }
        Task { @MainActor in
            onChange(object[keyPath: keypath])
            observeObject(object, keypath: keypath, onChange: onChange)
        }
    }
}
