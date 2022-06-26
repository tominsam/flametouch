// Copyright 2019 Thomas Insam. All rights reserved.

import UIKit

/// Renders the "connect to wifi" messag
public class WifiView: UIView {
    let titleView = UILabel()
    let subtitleView = UILabel()

    public init() {
        super.init(frame: .zero)
        backgroundColor = .systemBackground

        titleView.font = UIFont.preferredFont(forTextStyle: .title1)
        titleView.textAlignment = .center
        titleView.numberOfLines = 0
        titleView.text = NSLocalizedString("No wireless network found", comment: "Title for a screen displayed when there is no WiFi network")

        subtitleView.textAlignment = .center
        subtitleView.numberOfLines = 0
        subtitleView.font = UIFont.preferredFont(forTextStyle: .title2)
        subtitleView.text = NSLocalizedString("Connect to a WiFi network to see local services.", comment: "Subtitle for a screen displayed when there is no WiFi network")

        let guide = readableContentGuide
        addSubviewWithConstraints(titleView, [
            titleView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 180),
            titleView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            titleView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
        ])
        addSubviewWithConstraints(subtitleView, [
            subtitleView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 40),
            subtitleView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            subtitleView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
