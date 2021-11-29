// Copyright 2019 Thomas Insam. All rights reserved.

import UIKit

extension UITableView {
    func setupForAutolayout() {
        estimatedRowHeight = 80.0
        rowHeight = UITableView.automaticDimension
        cellLayoutMarginsFollowReadableWidth = true
        // catalyst keyboard focus fix
        selectionFollowsFocus = true
        // Fixes a background color overscroll bug
        backgroundView = UIView()
        layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
}

@objc
public protocol Reusable {

    @objc
    static var reuseId: String { get }

}

public extension UITableView {
    func registerReusableCell<T>(_ klass: T.Type) where T: Reusable, T: UITableViewCell {
        register(T.self, forCellReuseIdentifier: T.reuseId)
    }

    func registerReusableHeaderFooterView<T>(_ klass: T.Type) where T: Reusable, T: UITableViewHeaderFooterView {
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
