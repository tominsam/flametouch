// Copyright 2016 Thomas Insam. All rights reserved.

import Foundation

class ServiceNamer {
    // Ordered list of "important" service names - these will be used to extract the
    // host name preferentially
    enum ImportantServices: String, CaseIterable {
        // Order here is important
        case airplay = "_airplay."
        case airport = "_airport."
        case rdlink = "_rdlink."
        case companionLink = "_companion-link."
        case sleep = "_sleep-proxy."
        case homeassistant = "_home-assistant."
        case homekit = "_hap."
        case ssh = "_ssh."
        case smb = "_smb."
        case printer = "_ipp."
        case chromecast = "_googlecast."
        case flametouch = "_flametouch."
        case dyson = "_dyson_mqtt."
        case alexa = "_alexa."
        case eero = "_eero."
        case eeroGw = "_eerogw."

        // needs to be near bottom, lots of things have matter
        // support, it's only the really simples stuff that can't
        // advertise anything better.
        case matter = "_matter."
    }

    static func nameForServices(_ services: Set<Service>) -> String? {
        // Keep services order stable in the case that a device advertises >1 service with a given type.
        // Order here isn't very important, it just needs to be stable.
        let sortedServices = services.sorted { $0.name < $1.name }
        // Look for important names first. The **first** one we find will name the service
        for name in ImportantServices.allCases {
            guard let service = sortedServices.filter({ $0.type.starts(with: name.rawValue) }).first else { continue }
            // order here is not important
            switch name {
            case .chromecast:
                let map = service.data
                if let name = map["fn"] {
                    return name
                } else {
                    return service.name
                }

            case .printer:
                if service.name.contains(" @ ") {
                    // "printer name @ computer name" for windows printer sharing
                    return service.name.components(separatedBy: " @ ")[1]
                }

            case .dyson:
                // In theory I could do serial number prefix matching here
                // but there's very little else on the record.
                return "Dyson"

            case .homekit:
                if let modelName = service.data["md"] {
                    return "\(modelName) (\(service.name))"
                }

            case .airplay:
                if let manufacturer = service.data["manufacturer"] {
                    return "\(manufacturer) (\(service.name))"
                } else if let model = service.data["model"] {
                    if model.starts(with: "AudioAccessory1,") {
                        return "HomePod (\(service.name))"
                    } else if model.starts(with: "AudioAccessory5,") {
                        return "HomePod Mini (\(service.name))"
                    } else if model.starts(with: "AppleTV") {
                        return "Apple TV (\(service.name))"
                    }
                }
            case .homeassistant:
                return "Home Assistant (\(service.data["location_name"] ?? "New"))"

            case .eeroGw:
                return "Eero (Gateway)"

            case .matter:
                return "Matter device (\(service.name))"

            default:
                break
            }
            return service.name
        }

        // If we got to here, then we didn't find a special case service.
        // fallback to whichever is shorter out of the hostname and the first service name
        // (I'm assuming that short == pithy)
        guard let service = services.first else { return nil }

        return [
            service.addressCluster.displayName,
            service.name,
        ].compactMap { $0 }.sorted { $0.count < $1.count }.first
    }
}
