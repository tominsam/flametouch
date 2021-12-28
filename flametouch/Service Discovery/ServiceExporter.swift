// Copyright 2021 Thomas Insam. All rights reserved.

import Foundation

class ServiceExporter {

    static func export(hosts: [Host]) -> URL? {

        var groupsJson: [Any] = []
        var hostCount = 0
        var serviceCount = 0
        for host in hosts {
            hostCount += 1
            var groupJson: [String: Any] = [:]
            groupJson["name"] = host.name
            var addressesJson: [String] = []
            for address in host.displayAddresses {
                addressesJson.append(address)
            }
            groupJson["addresses"] = addressesJson

            var servicesJson: [Any] = []
            for service in host.displayServices {
                serviceCount += 1
                var serviceJson: [String: Any] = [:]
                serviceJson["name"] = service.name
                serviceJson["port"] = service.port
                serviceJson["type"] = service.type
                serviceJson["domain"] = service.domain
                var addressesJson: [String] = []
                for address in service.displayAddresses {
                    addressesJson.append(address)
                }
                serviceJson["addresses"] = addressesJson
                for (key, value) in service.data {
                    serviceJson[key] = value
                }
                servicesJson.append(serviceJson)
            }
            groupJson["services"] = servicesJson
            groupsJson.append(groupJson)
        }

        let file = "flame_export.json"

        guard let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true).first,
              let path = NSURL(fileURLWithPath: dir).appendingPathComponent(file)
        else {
            return nil
        }

        NSLog("path is %@", path.path)
        let output = OutputStream(toFileAtPath: path.path, append: false)!
        output.open()
        JSONSerialization.writeJSONObject(groupsJson, to: output, options: JSONSerialization.WritingOptions.prettyPrinted, error: nil)
        output.close()

        return path
    }

}
