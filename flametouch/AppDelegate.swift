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

    var window: UIWindow?
    let browser = ServiceBrowser()

    static func instance() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        ELog("started!")

        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.backgroundColor = .systemBackground
        self.window!.tintColor = .red

        UINavigationBar.appearance().barStyle = .black
        UINavigationBar.appearance().isTranslucent = true
        UINavigationBar.appearance().barTintColor = .red
        UINavigationBar.appearance().tintColor = .white

        let viewController = ServicesViewController()

        let navigationController = UINavigationController(rootViewController: viewController)

        // iOS 13 nav bar theming
        if #available(iOS 13.0, *) {
            let foreground: UIColor = .dynamic(light: .white, dark: .red)

            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = .dynamic(light: .red, dark: .systemGray6)
            appearance.titleTextAttributes = [
                .foregroundColor: foreground
            ]
            appearance.largeTitleTextAttributes = [
                .foregroundColor: foreground
            ]
            let buttonAppearance = UIBarButtonItemAppearance()
            buttonAppearance.normal.titleTextAttributes = [
                .foregroundColor: foreground
            ]
            appearance.buttonAppearance = buttonAppearance
            navigationController.navigationBar.scrollEdgeAppearance = appearance
            navigationController.navigationBar.standardAppearance = appearance
            navigationController.navigationBar.compactAppearance = appearance
            navigationController.navigationBar.tintColor = foreground
        }

        self.window!.rootViewController = navigationController;
        self.window!.makeKeyAndVisible()
        
        //precondition(false)
        
        return true;
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        browser.pause()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        browser.resume()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

fileprivate extension UIColor {
    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return dark
            case .light:
                return light
            default:
                return light
            }
        }

    }
}
