// Copyright 2016 Thomas Insam. All rights reserved.

import Foundation
import UIKit
import Utils

public class SimpleCell: UITableViewCell, Reusable {
    public static var reuseId: String = "SimpleCell"

    lazy var titleView = with(UILabel()) {
        $0.font = UIFont.preferredFont(forTextStyle: .body)
        $0.textColor = .label
        $0.highlightedTextColor = .white
    }

    lazy var subtitleView = with(UILabel()) {
        $0.font = UIFont.preferredFont(forTextStyle: .body)
        $0.textColor = .secondaryLabel
        $0.highlightedTextColor = .white
    }

    lazy var titleStack = with(UIStackView(arrangedSubviews: [titleView, subtitleView])) {
        $0.axis = .vertical
        $0.alignment = .fill
        $0.spacing = 8
    }

    public lazy var iconView = with(UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))) {
        $0.contentMode = .scaleAspectFit
        $0.image = nil
        $0.tintColor = .label
    }

    public lazy var rightView = with(UILabel()) {
        $0.font = UIFont.preferredFont(forTextStyle: .body)
        $0.textColor = .secondaryLabel
        $0.highlightedTextColor = .white
    }

    lazy var outerStack = with(UIStackView(arrangedSubviews: [iconView, titleStack, rightView])) {
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

    public override init(style _: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(outerStack)
        outerStack.snp.makeConstraints { make in
            make.edges.equalTo(contentView.layoutMarginsGuide)
            make.height.greaterThanOrEqualTo(60)
        }

        prepareForReuse()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("no")
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        title = nil
        subtitle = nil
        right = nil
        icon = nil
    }

    public var title: String? {
        get { return titleView.text }
        set {
            titleView.text = newValue
            titleView.isHidden = newValue == nil
        }
    }

    public var subtitle: String? {
        get { return subtitleView.text }
        set {
            subtitleView.text = newValue
            subtitleView.isHidden = newValue == nil
        }
    }

    public var right: String? {
        get { return rightView.text }
        set {
            rightView.text = newValue
            rightView.isHidden = newValue == nil
        }
    }

    public var icon: UIImage? {
        get { return iconView.image }
        set {
            iconView.image = newValue
            iconView.isHidden = newValue == nil
        }
    }
}
