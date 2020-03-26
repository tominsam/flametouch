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

    override func buildMenu(with builder: UIMenuBuilder) {
        let exportCommand = UIKeyCommand(
            title: NSLocalizedString("Export…", comment: ""),
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

    func exportData() -> URL? {

        var groupsJson : [Any] = []
        var host_count = 0
        var service_count = 0
        for serviceGroup in browser.serviceGroups {
            host_count += 1
            var groupJson : [String:Any] = [:]
            groupJson["name"] = serviceGroup.title
            var addressesJson : [String] = []
            for address in serviceGroup.addresses {
                addressesJson.append(address)
            }
            groupJson["addresses"] = addressesJson

            var servicesJson : [Any] = []
            for service in serviceGroup.services {
                service_count += 1
                var serviceJson : [String: Any] = [:]
                serviceJson["name"] = service.name
                serviceJson["port"] = service.port
                serviceJson["type"] = service.type
                var addressesJson : [String] = []
                let addresses = service.addresses!.compactMap { getIFAddress($0) }
                for address in addresses {
                    addressesJson.append(address)
                }
                serviceJson["addresses"] = addressesJson
                if let txtRecord = service.txtRecordData() {
                    for (key, value) in NetService.dictionary(fromTXTRecord: txtRecord) {
                        serviceJson[key] = String(bytes: value, encoding: .utf8) ?? value.hex
                    }
                }

                servicesJson.append(serviceJson)
            }
            groupJson["services"] = servicesJson

            groupsJson.append(groupJson)
        }

        let file = "services_export.json"

        guard let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true).first,
            let path = NSURL(fileURLWithPath: dir).appendingPathComponent(file)
            else {
                return nil
        }

        NSLog("path is \(path.path)")
        let output = OutputStream(toFileAtPath: path.path, append: false)!
        output.open()
        JSONSerialization.writeJSONObject(groupsJson, to: output, options: JSONSerialization.WritingOptions.prettyPrinted, error: nil)
        output.close()

        return path
    }

}
