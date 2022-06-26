// Copyright 2019 Thomas Insam. All rights reserved.

import UIKit
import Views

extension UITableView {
    func setupForAutolayout() {
        estimatedRowHeight = 80.0
        rowHeight = UITableView.automaticDimension
        cellLayoutMarginsFollowReadableWidth = true
        // catalyst keyboard focus fix
        // selectionFollowsFocus = true
        remembersLastFocusedIndexPath = true
        // Fixes a background color overscroll bug
        backgroundView = UIView()
        layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
}
