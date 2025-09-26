// Copyright 2015 Thomas Insam. All rights reserved.

import SafariServices
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let serviceController: ServiceController = ServiceControllerImpl()
    var serviceRefreshTask: Task<Void, Never>?

    static var instance: AppDelegate {
        // swiftlint:disable:next force_cast
        UIApplication.shared.delegate as! AppDelegate
    }

    // Pulled from one of the reds in the app icon, this looks pretty good to me in both themes
    static let tintColor = UIColor(red: 204.0 / 255, green: 59.0 / 255, blue: 72.0 / 255, alpha: 1)

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        true
    }

    func application(
        _: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        switch options.userActivities.first?.activityType {
        case "org.jerakeen.flametouch.about":
            return UISceneConfiguration(name: "About", sessionRole: connectingSceneSession.role)
        default:
            return UISceneConfiguration(name: "Main", sessionRole: connectingSceneSession.role)
        }
    }

//    override func buildMenu(with builder: UIMenuBuilder) {
//        let refreshCommand = UIKeyCommand(
//            title: String(
//                localized: "Refresh",
//                comment: "Menu item to refresh network data"
//            ),
//            image: nil,
//            action: #selector(BrowseViewController.handleTableRefresh(sender:)),
//            input: "R",
//            modifierFlags: .command,
//            propertyList: nil
//        )
//
//        let exportCommand = UIKeyCommand(
//            title: String(localized: "Export…", comment: "Menu item to export network data"),
//            image: nil,
//            action: #selector(CustomSplitViewController.saveExportedData),
//            input: "E",
//            modifierFlags: .command,
//            propertyList: nil
//        )
//
//        let exportMenu = UIMenu(
//            title: "",
//            image: nil,
//            identifier: UIMenu.Identifier("org.jerakeen.flametouch.menus.export"),
//            options: .displayInline,
//            children: [refreshCommand, exportCommand]
//        )
//
//        builder.insertChild(exportMenu, atStartOfMenu: .file)
//
//        builder.remove(menu: .help)
//    }

    func sceneDelegateWillEnterForeground(_: SceneDelegate) {
        serviceRefreshTask?.cancel()
        serviceRefreshTask = Task {
            ELog("Starting heartbeat")
            await serviceController.start()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                if Task.isCancelled { break }
                ELog("tick")
                await serviceController.stop()
                await serviceController.start()
            }
            ELog("Stopping heartbeat")
            await serviceController.stop()
        }
    }

    func sceneDelegateDidEnterBackground(_: SceneDelegate) {
        Task {
            // If there are no more foreground scenes, stop the service browser
            if UIApplication.shared.connectedScenes.map(\.activationState).contains(
                [.foregroundActive, .foregroundInactive]
            ) {
                return
            }
            serviceRefreshTask?.cancel()
            serviceRefreshTask = nil
        }
    }
}
