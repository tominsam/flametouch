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
        self.title = "About"
        self.view = UIView(frame: CGRect.null)
        let webView = UIWebView()
        self.view.addSubview(webView)
        webView.autoPinEdgesToSuperviewEdges()
        let localfilePath = Bundle.main.url(forResource: "about", withExtension: "html")
        webView.loadRequest(URLRequest(url: localfilePath!))
    }
}
