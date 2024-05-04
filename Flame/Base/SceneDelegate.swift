// Copyright 2019 Thomas Insam. All rights reserved.

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        ELog("Scene started")
        guard let windowScene = scene as? UIWindowScene else { fatalError() }

        #if targetEnvironment(macCatalyst)
            // Hide window titlebar (you can still move window using the navigation bar)
            if let titlebar = windowScene.titlebar {
                titlebar.titleVisibility = .hidden
                titlebar.toolbar = nil
            }
        #endif

        let serviceController = AppDelegate.instance.serviceController

        window = UIWindow(windowScene: windowScene)
        let browseVc = BrowseViewController(serviceController: serviceController)
        window?.rootViewController = CustomSplitViewController(primaryViewController: browseVc)
        window?.tintColor = AppDelegate.tintColor
        window?.makeKeyAndVisible()
    }

    func sceneDidEnterBackground(_: UIScene) {
        ELog("sceneDidEnterBackground")
        AppDelegate.instance.sceneDelegateDidEnterBackground(self)
    }

    func sceneWillEnterForeground(_: UIScene) {
        ELog("sceneWillEnterForeground")
        AppDelegate.instance.sceneDelegateWillEnterForeground(self)
    }
}
