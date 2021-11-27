// Copyright 2019 Thomas Insam. All rights reserved.

import UIKit

class AboutSceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        NSLog("About Scene started")
        guard let windowScene = scene as? UIWindowScene else { fatalError() }
        windowScene.sizeRestrictions?.minimumSize = CGSize(width: 480, height: 640)
        windowScene.sizeRestrictions?.maximumSize = CGSize(width: 480, height: 640)

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = AboutViewController()
        window?.makeKeyAndVisible()
    }

}
