//
//  AppDelegate.swift
//  flametouch
//
//  Created by tominsam on 10/10/15.
//  Copyright © 2015 tominsam. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let browser = ServiceBrowser()

    static func instance() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        browser.resume()
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        switch options.userActivities.first?.activityType {
        case "org.jerakeen.flametouch.about":
            return UISceneConfiguration(name: "About", sessionRole: .windowApplication)
        default:
            return UISceneConfiguration(name: "Main", sessionRole: .windowApplication)
        }

    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        browser.pause()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        browser.resume()
    }

}
