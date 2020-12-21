//
//  ViewExtensions.swift
//  Flame
//
//  Created by tominsam on 10/15/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func pinEdgesTo(guide: UILayoutGuide) {
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
        leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true
        bottomAnchor.constraint(equalTo: guide.bottomAnchor).isActive = true
    }

    func pinEdgesTo(view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    func addSubviewWithConstraints(_ view: UIView, _ constraints: [NSLayoutConstraint] = []) {
        addSubviewsWithConstraints([view], constraints)
    }

    func addSubviewsWithConstraints(_ views: [UIView], _ constraints: [NSLayoutConstraint] = []) {
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        if !constraints.isEmpty {
            NSLayoutConstraint.activate(constraints)
        }
    }

    func addSubviewWithInsets(_ view: UIView, _ insets: UIEdgeInsets = .zero) {
        addSubviewWithConstraints(view, [
            view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            view.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
            ])
    }

    func addSubviewInCenter(_ view: UIView) {
        addSubviewWithConstraints(view, [
            view.centerXAnchor.constraint(equalTo: centerXAnchor),
            view.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
    }
}
