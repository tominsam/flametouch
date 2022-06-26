// Copyright 2016 Thomas Insam. All rights reserved.

import SafariServices
import UIKit
import WebKit

class AboutViewController: UIViewController, WKNavigationDelegate {
    override func viewDidLoad() {
        let webView = WKWebView()
        webView.navigationDelegate = self
        let localfilePath = Bundle.main.url(forResource: "about", withExtension: "html")!
        webView.loadFileURL(localfilePath, allowingReadAccessTo: localfilePath)

        // Make view transparent so I can use the system background and avoid FOUC
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground

        view.addSubview(webView)
        webView.pinEdgesTo(view: view)
    }

    func webView(_: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            UIApplication.shared.open(navigationAction.request.url!, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    @objc func done() {
        dismiss(animated: true, completion: nil)
    }
}
