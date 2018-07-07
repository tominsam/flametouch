//
//  AboutViewController.swift
//  flametouch
//
//  Created by tominsam on 2/27/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import UIKit
import SafariServices
import Crashlytics
import WebKit

class AboutViewController: UIViewController, WKNavigationDelegate {

    override func loadView() {
        Answers.logContentView(withName: "about", contentType: "screen", contentId: nil, customAttributes: nil)

        title = "About"
        view = UIView(frame: CGRect.null)
        view.backgroundColor = UIColor.white
        perform(#selector(initWebview), with: nil, afterDelay: 0)
    }
    
    @objc func initWebview() {
        let webView = WKWebView()
        view.addSubview(webView)
        view.backgroundColor = UIColor.white
        webView.backgroundColor = UIColor.white
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.pinEdgesTo(guide: view.safeAreaLayoutGuide)
        webView.navigationDelegate = self
        let localfilePath = Bundle.main.url(forResource: "about", withExtension: "html")
        webView.load(URLRequest(url: localfilePath!))
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
