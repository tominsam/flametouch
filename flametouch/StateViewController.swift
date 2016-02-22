//
//  StateViewController.swift
//  flametouch
//
//  Created by tominsam on 10/11/15.
//  Copyright © 2015 tominsam. All rights reserved.
//

import UIKit

public class StateViewController: UIViewController {

    public enum StatefulViewControllerState: String {
        case Content = "content"
        case Loading = "loading"
        case Error = "error"
        case Empty = "empty"
    }


    override public func viewDidLoad() {
        super.viewDidLoad()
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

}
