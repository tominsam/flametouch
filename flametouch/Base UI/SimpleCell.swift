// Copyright 2016 Thomas Insam. All rights reserved.

import Foundation
import UIKit

class SimpleCell: UITableViewCell, Reusable {
    static var reuseId: String = "SimpleCell"

    lazy var titleView = configure(UILabel()) {
        $0.font = UIFont.preferredFont(forTextStyle: .body)
        $0.textColor = .label
    }

    lazy var subtitleView = configure(UILabel()) {
        $0.font = UIFont.preferredFont(forTextStyle: .body)
        $0.textColor = .secondaryLabel
        $0.highlightedTextColor = .label
    }

    lazy var titleStack = configure(UIStackView(arrangedSubviews: [titleView, subtitleView])) {
        $0.axis = .vertical
        $0.alignment = .fill
        $0.spacing = 8
    }

    lazy var iconView = configure(UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))) {
        $0.contentMode = .scaleAspectFit
        $0.image = nil
        $0.tintColor = .label
    }

    lazy var rightView = configure(UILabel()) {
        $0.font = UIFont.preferredFont(forTextStyle: .body)
        $0.textColor = .secondaryLabel
        $0.highlightedTextColor = .label
    }

    lazy var outerStack = configure(UIStackView(arrangedSubviews: [iconView, titleStack, rightView])) {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.distribution = .fill
        $0.spacing = 8
        $0.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        $0.isLayoutMarginsRelativeArrangement = true
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        rightView.setContentHuggingPriority(.required, for: .horizontal)
        titleStack.setContentHuggingPriority(.defaultLow, for: .horizontal)

        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        rightView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleStack.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        // Force a background color to avoid buggy mac selection styles
        selectedBackgroundView = configure(UIView()) {
            $0.backgroundColor = .systemGray5
        }

        contentView.addSubviewWithConstraints(outerStack, [
            outerStack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            outerStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            outerStack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            outerStack.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])

        prepareForReuse()
    }

    required init?(coder: NSCoder) {
        fatalError("no")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        title = nil
        subtitle = nil
        right = nil
        icon = nil
    }

    var title: String? {
        get { return titleView.text }
        set {
            titleView.text = newValue
            titleView.isHidden = newValue == nil
        }
    }

    var subtitle: String? {
        get { return subtitleView.text }
        set {
            subtitleView.text = newValue
            subtitleView.isHidden = newValue == nil
        }
    }

    var right: String? {
        get { return rightView.text }
        set {
            rightView.text = newValue
            rightView.isHidden = newValue == nil
        }
    }

    var icon: UIImage? {
        get { return iconView.image }
        set {
            iconView.image = newValue
            iconView.isHidden = newValue == nil
        }
    }

}
