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
                let categoryInt: UInt = service.data["ci"].map { UInt($0) ?? 0 } ?? 0
                let category = HomeAssistantCategory(rawValue: categoryInt)
                let modelName = service.data["md"]
                if let category {
                    return "\(category.name) (\(modelName ?? service.name))"
                } else if let modelName {
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

enum HomeAssistantCategory: UInt {
    case other = 1
    case bridge = 2
    case fan = 3
    case garage = 4
    case lightbulb = 5
    case doorLock = 6
    case outlet = 7
    case `switch` = 8
    case thermostat = 9
    case sensor = 10
    case securitySystem = 11
    case door = 12
    case window = 13
    case windowCovering = 14
    case programmableSwitch = 15
    case rangeExtender = 16
    case ipCamera = 17
    case videoDoorBell = 18
    case airPurifier = 19
    case airHeater = 20
    case airConditioner = 21
    case airHumidifier = 22
    case airDehumidifier = 23
    case appleTV = 24
    case speaker = 26
    case airport = 27
    case sprinkler = 28
    case faucet = 29
    case showerHead = 30
    case television = 31
    case targetController = 32
    case router = 33
    case audioReceiver = 34
    case tvSetTopBox = 35
    case tvStreamingStick = 36

    var name: String {
        switch self {
        case .other: return "Other"
        case .bridge: return "Bridge"
        case .fan: return "Fan"
        case .garage: return "Garage"
        case .lightbulb: return "Lightbulb"
        case .doorLock: return "Door Lock"
        case .outlet: return "Outlet"
        case .switch: return "Switch"
        case .thermostat: return "Thermostat"
        case .sensor: return "Sensor"
        case .securitySystem: return "Security System"
        case .door: return "Door"
        case .window: return "Window"
        case .windowCovering: return "Window Covering"
        case .programmableSwitch: return "Programmable Switch"
        case .rangeExtender: return "Range Extender"
        case .ipCamera: return "IP Camera"
        case .videoDoorBell: return "Video Door Bell"
        case .airPurifier: return "Air Purifier"
        case .airHeater: return "Air Heater"
        case .airConditioner: return "Air Conditioner"
        case .airHumidifier: return "Air Humidifier"
        case .airDehumidifier: return "Air Dehumidifier"
        case .appleTV: return "Apple TV"
        case .speaker: return "Speaker"
        case .airport: return "Airport"
        case .sprinkler: return "Sprinkler"
        case .faucet: return "Faucet"
        case .showerHead: return "Shower Head"
        case .television: return "Television"
        case .targetController: return "Target Controller"
        case .router: return "Router"
        case .audioReceiver: return "Audio Receiver"
        case .tvSetTopBox: return "TV Set Top Box"
        case .tvStreamingStick: return "TV Streaming Stick"
        }
    }
}
