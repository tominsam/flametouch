//
//  SceneDelegate.swift
//  Flame
//
//  Created by tominsam on 10/18/19.
//  Copyright © 2019 tominsam. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        NSLog("Scene started")
        guard let windowScene = scene as? UIWindowScene else { fatalError() }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = CustomSplitViewController().configured {
            $0.maximumPrimaryColumnWidth = 640
            $0.minimumPrimaryColumnWidth = 320
            $0.preferredPrimaryColumnWidthFraction = 0.4
            $0.setMasterViewController(ServicesViewController())
        }
        window?.tintColor = .systemRed
        window?.makeKeyAndVisible()

    }

}
