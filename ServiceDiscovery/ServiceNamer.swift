// Copyright 2016 Thomas Insam. All rights reserved.

import Foundation
import SwiftUI

class ServiceNamer {

    // Ordered list of "important" service names - these will be used to extract the
    // host name preferentially
    enum ImportantServices: String, CaseIterable {
        // Order here is important

        // Anything that's very device-specific
        case dyson = "_dyson_mqtt._tcp."
        case sonos = "_sonos._tcp."
        case eero = "_eero._tcp."
        case eeroGw = "_eerogw._tcp."
        case zoomRooms = "_zoomrooms._tcp."
        case printer = "_ipp._tcp."
        case scanner = "_scanner._tcp."
        case chromecast = "_googlecast._tcp."

        // most apple stuff
        case raop = "_raop._tcp."
        case airplay = "_airplay._tcp."
        case airport = "_airport._tcp."
        case rdlink = "_rdlink._tcp."
        case remotePairing = "_remotepairing._tcp."
        case companionLink = "_companion-link._tcp."
        case sleep = "_sleep-proxy._tcp."

        case homeassistant = "_home-assistant._tcp."
        case homekit = "_hap._tcp."
        case alexa = "_alexa._tcp."
        case flametouch = "_flametouch._tcp."

        // servers
        case ssh = "_ssh._tcp."
        case smb = "_smb._tcp."
        case http = "_http._tcp."
        case https = "_https._tcp."

        // needs to be near bottom, lots of things have matter
        // support, it's only the really simple stuff that can't
        // advertise anything better.
        case matter = "_matter._tcp."

        /// Returns an SFSymbols string
        var hostIcon: String {
            switch self {
            case .raop: return "airplayaudio"
            case .airplay: return "airplayvideo"
            case .airport: return "wifi.router"
            case .companionLink: return "iphone"
            case .remotePairing: return "iphone"
            case .rdlink: return "iphone"
            case .sleep: return "sleep"
            case .homeassistant: return "house.fill"
            case .homekit: return "homekit"
            case .ssh: return "terminal"
            case .smb: return "externaldrive"
            case .printer: return "printer"
            case .scanner: return "scanner"
            case .chromecast: return "tv"
            case .flametouch: return "flame"
            case .dyson: return "fan"
            case .alexa: return "mic"
            case .eero, .eeroGw: return "wifi.router"
            case .zoomRooms: return "video"
            case .sonos: return "hifispeaker"
            case .http, .https: return "globe"
            case .matter: return "matter.logo"
            }
        }

        /// String to show on "open" action button
        var openAction: String {
            switch self {
            case .http, .https: return "Open web page"
            case .ssh: return "Connect to SSH server"
            case .smb: return "Connect to file server"
            case .sonos: return "See Sonos status"
            default: return "Open service"
            }
        }
    }

    struct OpenableService {
        let url: URL
        let action: String
        let icon: String

        init?(_ service: Service) {
            guard let url = service.url, let named = ImportantServices(rawValue: service.type) else {
                return nil
            }
            self.url = url
            self.action = named.openAction
            self.icon = named.hostIcon
        }
    }

    static func hostIcon(forServices services: Set<Service>) -> String {
        // Keep services order stable in the case that a device advertises >1 service with a given type.
        // Order here isn't very important, it just needs to be stable.
        let sortedServices = services.sorted { $0.name < $1.name }
        // Look for important names first. The **first** one we find will name the service
        for name in ImportantServices.allCases {
            guard let service = sortedServices.first(where: { $0.type == name.rawValue }) else { continue }
            // order here is not important
            switch name {

            case .raop:
                guard let am = service.data["am"] else { break }
                return AppleHardware.from(am: am).icon

            case .companionLink:
                guard let am = service.data["rpMd"] else {
                    // raop comes first and always has am. companionlink on static hardware
                    // (tv, homepod) tends to have rpMd, but phones + ipads don't, so if it's
                    // missing it's a portable device?
                    return "iphone"
                }
                return AppleHardware.from(am: am).icon

            default:
                break
            }

            return name.hostIcon
        }

        return "desktopcomputer"
    }

    static func nameForServices(_ services: Set<Service>) -> String? {
        // Keep services order stable in the case that a device advertises >1 service with a given type.
        // Order here isn't very important, it just needs to be stable.
        let sortedServices = services.sorted { $0.name < $1.name }
        // Look for important names first. The **first** one we find will name the service
        for name in ImportantServices.allCases {
            guard let service = sortedServices.first(where: { $0.type == name.rawValue }) else { continue }
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

            case .scanner:
                if service.name.contains(" @ ") {
                    // "printer name @ computer name" for windows printer sharing
                    return service.name.components(separatedBy: " @ ")[1]
                }

            case .sonos:
                if service.name.contains("@") {
                    let name = service.name.components(separatedBy: "@")[1]
                    return "Sonos (\(name))"
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

            case .raop:
                if service.name.contains("@") {
                    if let am = service.data["am"] {
                        let name = service.name.components(separatedBy: "@").last ?? service.name
                        let hardware = AppleHardware.from(am: am)
                        return hardware.displayName(for: name)
                    }
                }

            case .airplay:
                if let manufacturer = service.data["manufacturer"] {
                    return "\(manufacturer) (\(service.name))"
                } else if let model = service.data["model"] {
                    let hardware = AppleHardware.from(am: model)
                    return hardware.displayName(for: service.name)
                }
            case .homeassistant:
                return "Home Assistant (\(service.data["location_name"] ?? "New"))"

            case .zoomRooms:
                return "Zoom Room (\(service.name))"

            case .eeroGw:
                return "Eero (Gateway)"

            case .matter:
                return "Matter device (\(service.name))"

            case .remotePairing:
                continue

            default:
                break

            }

            if service.name.contains("@") {
                return service.name.components(separatedBy: "@")[1].trimmingCharacters(in: .whitespaces)
            }
            return service.name
        }

        // If we got to here, then we didn't find a special case service.
        // fallback to whichever is shorter out of the hostname and the first service name
        // (I'm assuming that short == pithy)
        guard let service = sortedServices.first else { return nil }

        return [
            service.addressCluster.displayName,
            service.name,
        ].compactMap { $0 }.sorted { $0.count < $1.count }.first
    }
}

#Preview("Service Icons") {
    List(ServiceNamer.ImportantServices.allCases, id: \.self) { type in
        Label(type.rawValue, systemImage: type.hostIcon)
    }
}

enum AppleHardware {
    // https://openairplay.github.io/airplay-spec/service_discovery.html
    // https://github.com/postlund/pyatv/blob/master/docs/documentation/protocols.md

    case appleTv
    case homepod
    case homepodMini
    case mac
    case unknown(String)

    static func from(am: String) -> Self {
        if am.starts(with: "AppleTV") {
            return .appleTv
        } else if am.starts(with: "AudioAccessory5") {
            return .homepodMini
        } else if am.starts(with: "AudioAccessory") {
            return .homepod
        } else if am.starts(with: "Mac") {
            return .mac
        }
        return .unknown(am)
    }

    var icon: String {
        switch self {
        case .appleTv:
            "tv"
        case .homepod:
            "homepod.fill"
        case .homepodMini:
            "homepod.mini.fill"
        case .mac:
            "macbook"
        case .unknown:
            "airplayaudio"
        }
    }

    var name: String {
        switch self {
        case .appleTv:
            "AppleTV"
        case .homepod:
            "Homepod"
        case .homepodMini:
            "Homepod Mini"
        case .mac:
            "Mac"
        case .unknown(let name):
            name
        }
    }

    func displayName(for serviceName: String) -> String {
        if case .mac = self {
            return serviceName
        } else {
            return "\(name) (\(serviceName))"
        }

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
