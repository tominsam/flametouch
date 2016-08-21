//
//  StateViewController.swift
//  flametouch
//
//  Created by tominsam on 10/11/15.
//  Copyright © 2015 tominsam. All rights reserved.
//

import UIKit

open class StateViewController: UIViewController {

    public enum StatefulViewControllerState: String {
        case Content = "content"
        case Loading = "loading"
        case Error = "error"
        case Empty = "empty"
    }


    override open func viewDidLoad() {
        super.viewDidLoad()
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

}
