//
//  AboutViewController.swift
//  flametouch
//
//  Created by tominsam on 2/27/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import UIKit
import SafariServices

class AboutViewController: UIViewController, UIWebViewDelegate {

    override func loadView() {
        title = "About"
        view = UIView(frame: CGRect.null)
        view.backgroundColor = UIColor.white
        perform(#selector(initWebview), with: nil, afterDelay: 0)
        automaticallyAdjustsScrollViewInsets = false
    }
    
    func initWebview() {
        let webView = UIWebView()
        view.addSubview(webView)
        view.backgroundColor = UIColor.white
        view.isOpaque = true

        // limit webview width so lines aren't too long
        let guide = view.readableContentGuide
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
        webView.leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: guide.bottomAnchor).isActive = true

        webView.scrollView.contentInset.top = 40
        webView.delegate = self
        let localfilePath = Bundle.main.url(forResource: "about", withExtension: "html")
        webView.loadRequest(URLRequest(url: localfilePath!))
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == .linkClicked {
            //let controller = SFSafariViewController(url: request.url!)
            //navigationController?.pushViewController(controller, animated: true)
            
            UIApplication.shared.openURL(request.url!)
            return false
        }
        return true
    }
}
