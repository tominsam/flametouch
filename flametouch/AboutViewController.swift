//
//  AboutViewController.swift
//  flametouch
//
//  Created by tominsam on 2/27/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {

    override func loadView() {
        title = "About"
        view = UIView(frame: CGRect.null)
        view.backgroundColor = UIColor.white
        perform(#selector(initWebview), with: nil, afterDelay: 0)
    }
    
    func initWebview() {
        let webView = UIWebView()
        view.addSubview(webView)
        webView.autoPinEdgesToSuperviewEdges()
        webView.backgroundColor = UIColor.white
        view.backgroundColor = nil
        webView.scrollView.contentInset.top = 40
        let localfilePath = Bundle.main.url(forResource: "about", withExtension: "html")
        webView.loadRequest(URLRequest(url: localfilePath!))
    }
}
