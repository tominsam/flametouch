//
//  AboutViewController.swift
//  flametouch
//
//  Created by tominsam on 2/27/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import UIKit
import SafariServices
import WebKit

class AboutViewController: UIViewController, WKNavigationDelegate {

    override func viewDidLoad() {
        title = "About"
        let webView = WKWebView()
        webView.navigationDelegate = self
        let localfilePath = Bundle.main.url(forResource: "about", withExtension: "html")!
        webView.loadFileURL(localfilePath, allowingReadAccessTo: localfilePath)

        view.addSubview(webView)
        webView.pinEdgesTo(view: view)

        // Webview flashes white on load and I can't stop it
        webView.isHidden = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            webView.isHidden = false
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            UIApplication.shared.open(navigationAction.request.url!, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

}
