// Copyright 2019 Thomas Insam. All rights reserved.

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        NSLog("Scene started")
        guard let windowScene = scene as? UIWindowScene else { fatalError() }

        #if targetEnvironment(macCatalyst)
        if let titlebar = windowScene.titlebar {
            titlebar.titleVisibility = .hidden
            titlebar.toolbar = nil
        }
        #endif

        let serviceController = AppDelegate.instance.serviceController

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = configure(CustomSplitViewController(serviceController: serviceController)) {
            $0.maximumPrimaryColumnWidth = 640
            $0.minimumPrimaryColumnWidth = 320
            $0.preferredPrimaryColumnWidthFraction = 0.35
            $0.primaryBackgroundStyle = .none // Or .sidebar but I hate it.
            $0.setMasterViewController(BrowseViewController(serviceController: serviceController))
        }
        window?.tintColor = .systemRed
        window?.makeKeyAndVisible()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        ELog("sceneDidEnterBackground")
        AppDelegate.instance.sceneDelegateDidEnterBackground(self)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        ELog("sceneWillEnterForeground")
        AppDelegate.instance.sceneDelegateWillEnterForeground(self)
    }

}
