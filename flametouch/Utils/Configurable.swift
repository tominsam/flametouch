import Foundation

internal protocol Configurable { }

extension Configurable {
    func configured(transform: (inout Self) throws -> Void) rethrows -> Self {
        var mutableSelf = self
        try transform(&mutableSelf)
        return mutableSelf
    }
}

extension NSObject: Configurable { }
extension Array: Configurable { }
extension JSONDecoder: Configurable { }
extension JSONEncoder: Configurable { }
