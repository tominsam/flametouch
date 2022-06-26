// Copyright 2019 Thomas Insam. All rights reserved.

import UIKit

@objc
public protocol Reusable {
    @objc
    static var reuseId: String { get }
}

public extension UITableView {
    func registerReusableCell<T>(_: T.Type) where T: Reusable, T: UITableViewCell {
        register(T.self, forCellReuseIdentifier: T.reuseId)
    }

    func registerReusableHeaderFooterView<T>(_: T.Type) where T: Reusable, T: UITableViewHeaderFooterView {
        register(T.self, forHeaderFooterViewReuseIdentifier: T.reuseId)
    }

    func dequeueReusableCell<T>(for indexPath: IndexPath) -> T where T: Reusable, T: UITableViewCell {
        // swiftlint:disable:next force_cast
        return dequeueReusableCell(withIdentifier: T.reuseId, for: indexPath) as! T
    }

    func dequeueReusableHeaderFooterView<T>() -> T where T: Reusable, T: UITableViewHeaderFooterView {
        // swiftlint:disable:next force_cast
        return dequeueReusableHeaderFooterView(withIdentifier: T.reuseId) as! T
    }
}
