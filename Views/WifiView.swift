// Copyright 2019 Thomas Insam. All rights reserved.

import UIKit
import SnapKit

/// Renders the "connect to wifi" messag
public class WifiView: UIView {
    let titleView = UILabel()
    let subtitleView = UILabel()

    public init() {
        super.init(frame: .zero)
        backgroundColor = .systemBackground

        titleView.font = UIFont.preferredFont(forTextStyle: .title2)
        titleView.textAlignment = .center
        titleView.numberOfLines = 0
        titleView.text = String(localized: "No services found", comment: "Title for a screen displayed when there is no local network")

        subtitleView.textAlignment = .center
        subtitleView.numberOfLines = 0
        subtitleView.font = UIFont.preferredFont(forTextStyle: .body)
#if targetEnvironment(macCatalyst)
        subtitleView.text = String(localized: "Connect to a WiFi or Wired network to see local services.", comment: "Subtitle for a screen displayed when there is no local network")
#else
        subtitleView.text = String(localized: "Connect to a WiFi network to see local services.", comment: "Subtitle for a screen displayed when there is no WiFi network")
#endif
        addSubview(titleView)
        titleView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(180)
            make.leading.trailing.equalToSuperview()
        }
        addSubview(subtitleView)
        subtitleView.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
