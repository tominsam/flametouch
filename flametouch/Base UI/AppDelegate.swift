// Copyright 2015 Thomas Insam. All rights reserved.

import UIKit
import SafariServices

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let serviceController: ServiceController = ServiceController()
    var serviceControllerRefCount: Int = 0
    var serviceRefreshTimer: Timer?

    static var instance: AppDelegate {
        // swiftlint:disable:next force_cast
        return UIApplication.shared.delegate as! AppDelegate
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        return true
    }

    func application(
        _ application: UIApplication,
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

    override func buildMenu(with builder: UIMenuBuilder) {
        let exportCommand = UIKeyCommand(
            title: NSLocalizedString("Export…", comment: "Menu item to export network data"),
            image: nil,
            action: #selector(CustomSplitViewController.saveExportedData),
            input: "E",
            modifierFlags: .command,
            propertyList: nil)

        let exportMenu = UIMenu(
            title: "",
            image: nil,
            identifier: UIMenu.Identifier("org.jerakeen.flametouch.menus.export"),
            options: .displayInline,
            children: [exportCommand])

        builder.insertChild(exportMenu, atStartOfMenu: .file)

        builder.remove(menu: .help)
    }

    func openUrl(_ url: URL?, from presentingViewController: UIViewController) {
        guard let url = url, let scheme = url.scheme else {
            return
        }
        switch scheme {
        case "http", "https":
            // If there's a universal link handler for this URL, use that for preference
            #if targetEnvironment(macCatalyst)
            UIApplication.shared.open(url)
            #else
            UIApplication.shared.open(url, options: [.universalLinksOnly: true]) { result in
                if !result {
                    let vc = SFSafariViewController(url: url)
                    vc.preferredControlTintColor = .systemRed
                    presentingViewController.present(vc, animated: true)
                }
            }
            #endif
        default:
            UIApplication.shared.open(url, options: [:]) { result in
                if !result {
                    let alertController = UIAlertController(title: "Can't open URL", message: "I couldn't open that URL - maybe you need a particular app installed", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default))
                    presentingViewController.present(alertController, animated: true)
                }
            }
        }
    }

    func sceneDelegateWillEnterForeground(_ sceneDelegate: SceneDelegate) {
        NetworkMonitor.shared.startMonitoring()
        serviceController.start()
        if serviceRefreshTimer == nil {
            serviceRefreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
                ELog("tick")
                self?.serviceController.stop()
                self?.serviceController.start()
            }
        }
    }

    func sceneDelegateDidEnterBackground(_ sceneDelegate: SceneDelegate) {
        // If there are no more forground scenes, stop the service browser
        for scene in UIApplication.shared.connectedScenes {
            ELog("State is \(scene.activationState.rawValue)")
            switch scene.activationState {
            case .foregroundActive, .foregroundInactive:
                // Found a foreground scene
                return
            case .unattached, .background:
                // Not a foreground scene
                break
            @unknown default:
                fatalError()
            }
        }
        ELog("Stopping ServiceController")
        serviceRefreshTimer?.invalidate()
        serviceRefreshTimer = nil
        serviceController.stop()
        NetworkMonitor.shared.stopMonitoring()
    }

}
