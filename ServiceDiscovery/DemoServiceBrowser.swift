// Copyright 2021 Thomas Insam <tom@movieos.org>

import Foundation

private extension Service {
    init(
        domain: String?,
        hostname: String,
        addresses: Set<String>,
        name: String,
        port: Int,
        data: [String: String],
        type: String
    ) {
        self.name = name
        self.type = type
        self.domain = domain
        addressCluster = AddressCluster.from(addresses: addresses, hostnames: [hostname])
        self.port = port
        self.data = data
        lastSeen = Date()
        alive = true
    }
}

// Demo data for screenshots so I don't need to stress about leaking things about my house
class DemoServiceBrowser: NSObject, ServiceBrowser {
    weak var delegate: ServiceBrowserDelegate?

    let services: Set<Service>
    override init() {
        services = [
            .init(
                domain: nil,
                hostname: "Tv.local.",
                addresses: ["192.168.0.167"],
                name: "TV",
                port: 7000,
                data: [
                    "acl": "0",
                    "btaddr": "F0:B3:EC:10:17:F7",
                    "deviceid": "F0:B3:EC:0A:DB:54",
                    "features": "0x4A7FDFD5,0xBC157FDE",
                    "flags": "0x18644",
                    "gcgl": "1",
                    "igl": "1",
                    "model": "AppleTV11,1",
                    "osvers": "15.1.1",
                    "protovers": "1.1",
                    "srcvers": "595.15.41",
                    "vv": "2",
                ],
                type: "_airplay._tcp."
            ),
            .init(
                domain: nil,
                hostname: "Tv.local.",
                addresses: ["192.168.0.167"],
                name: "TV",
                port: 49153,
                data: [
                    "rpAD": "202cb2fb89df",
                    "rpBA": "CD:F2:36:62:41:E4",
                    "rpFl": "0xB6782",
                    "rpHA": "18f0de2f5848",
                    "rpHI": "caee35a86e26",
                    "rpHN": "1607f07178e8",
                    "rpMac": "2",
                    "rpMd": "AppleTV11,1",
                    "rpMRtID": "F702BEA9-4EA6-4FDD-ACC3-C150AB10269D",
                    "rpVr": "310.7",
                ],
                type: "_companion-link._tcp."
            ),
            .init(
                domain: nil,
                hostname: "Tv.local.",
                addresses: ["192.168.0.167"],
                name: "46107942-AE96-58E8-BE72-B46A5F0C07A9",
                port: 65439,
                data: [
                    "si": "5F4302ED-0AA5-4391-A99B-59EA291711C7",
                ],
                type: "_homekit._tcp."
            ),
            .init(
                domain: nil,
                hostname: "Tv.local.",
                addresses: ["192.168.0.167"],
                name: "MyHome1",
                port: 49191,
                data: [
                    "nn": "MyHome1",
                    "rv": "1",
                    "sb": "00000031",
                    "tv": "1.2.0",
                    "vn": "Apple Inc.",
                    "xa": "AAD6B41C6DB109E8",
                    "xp": "6F07D1E49D904395",
                ],
                type: "_meshcop._udp."
            ),
            .init(
                domain: nil,
                hostname: "Tv.local.",
                addresses: ["192.168.0.167"],
                name: "F0B3EC0ADB54@Tv",
                port: 7000,
                data: [
                    "am": "AppleTV11,1",
                    "cn": "0,1,2,3",
                    "da": "true",
                    "et": "0,3,5",
                    "ft": "0x4A7FDFD5,0xBC157FDE",
                    "md": "0,1,2",
                    "ov": "15.1.1",
                    "pk": "ec881e2f7d05d42b98efb9d3f162265b5abc5705b1a4bb68b0833939287c0e7b",
                    "sf": "0x18644",
                    "tp": "UDP",
                    "vn": "65537",
                    "vs": "595.15.41",
                    "vv": "2",
                ],
                type: "_raop._tcp."
            ),
            .init(
                domain: nil,
                hostname: "Tv.local.",
                addresses: ["192.168.0.167"],
                name: "70-35-60-63.1 Tv",
                port: 62682,
                data: [:],
                type: "_sleep-proxy._udp."
            ),
            .init(
                domain: nil,
                hostname: "Tv.local.",
                addresses: ["192.168.0.167"],
                name: "TV",
                port: 853,
                data: [
                    "domain": "openthread.thread.home.arpa.",
                    "server-id": "9092e054e3ad3482",
                ],
                type: "_srpl-tls._tcp."
            ),
            .init(
                domain: nil,
                hostname: "BRN30055C42137D.local.",
                addresses: ["192.168.0.226"],
                name: "Brother HL-2270DW series",
                port: 80,
                data: [:],
                type: "_http._tcp."
            ),
            .init(
                domain: nil,
                hostname: "BRN30055C42137D.local.",
                addresses: ["192.168.0.226"],
                name: "Brother HL-2270DW series",
                port: 631,
                data: [
                    "adminurl": "http://BRN30055C42137D.local./",
                    "Binary": "T",
                    "Color": "F",
                    "Copies": "T",
                    "Duplex": "T",
                    "PaperCustom": "T",
                    "pdl": "application/vnd.hp-PCL",
                    "priority": "50",
                    "product": "(Brother HL-2270DW series)",
                    "qtotal": "1",
                    "rp": "duerqxesz5090",
                    "TBCP": "F",
                    "Transparent": "T",
                    "txtvers": "1",
                    "ty": "Brother HL-2270DW series",
                    "usb_MDL": "HL-2270DW series",
                    "usb_MFG": "Brother",
                ],
                type: "_ipp._tcp."
            ),
            .init(
                domain: nil,
                hostname: "BRN30055C42137D.local.",
                addresses: ["192.168.0.226"],
                name: "Brother HL-2270DW series",
                port: 9100,
                data: [
                    "adminurl": "http://BRN30055C42137D.local./",
                    "Binary": "T",
                    "Color": "F",
                    "Copies": "T",
                    "Duplex": "T",
                    "PaperCustom": "T",
                    "pdl": "application/vnd.hp-PCL",
                    "priority": "25",
                    "product": "(Brother HL-2270DW series)",
                    "qtotal": "1",
                    "TBCP": "T",
                    "Transparent": "F",
                    "txtvers": "1",
                    "ty": "Brother HL-2270DW series",
                    "usb_MDL": "HL-2270DW series",
                    "usb_MFG": "Brother",
                ],
                type: "_pdl-datastream._tcp."
            ),
            .init(
                domain: nil,
                hostname: "BRN30055C42137D.local.",
                addresses: ["192.168.0.226"],
                name: "Brother HL-2270DW series",
                port: 515,
                data: [
                    "adminurl": "http://BRN30055C42137D.local./",
                    "Binary": "T",
                    "Color": "F",
                    "Copies": "T",
                    "Duplex": "T",
                    "PaperCustom": "T",
                    "pdl": "application/vnd.hp-PCL",
                    "priority": "75",
                    "product": "(Brother HL-2270DW series)",
                    "qtotal": "1",
                    "rp": "duerqxesz5090",
                    "TBCP": "F",
                    "Transparent": "T",
                    "txtvers": "1",
                    "ty": "Brother HL-2270DW series",
                    "usb_MDL": "HL-2270DW series",
                    "usb_MFG": "Brother",
                ],
                type: "_printer._tcp."
            ),
            .init(
                domain: nil,
                hostname: "E6B-US-NCA1952A.local.",
                addresses: ["192.168.0.166"],
                name: "455_E6B-US-NCA1952A",
                port: 1883,
                data: [
                    "Service for E6B-US-NCA1952A": "",
                ],
                type: "_dyson_mqtt._tcp."
            ),
            .init(
                domain: nil,
                hostname: "Living-Room.local.",
                addresses: ["192.168.0.184"],
                name: "Living Room",
                port: 7000,
                data: [
                    "acl": "0",
                    "btaddr": "6B:A7:34:2D:49:FA",
                    "deviceid": "D4:90:9C:F1:4A:4B",
                    "features": "0x4A7FCA00,0xBC356BD0",
                    "fex": "AMp/StBrNbw",
                    "flags": "0x1a404",
                    "gcgl": "1",
                    "gid": "74F90143-03B1-5656-A7C7-9E1E5230FE13",
                    "gpn": "Living Room",
                    "igl": "1",
                    "model": "AudioAccessory1,1",
                    "osvers": "15.2",
                    "pi": "8215abb3-b28c-4de6-835f-44f7306f0920",
                    "pk": "a8a2e73f79e61e6948a3de650b88e2b7c4914e5675c516b55d26ba3857e0b3f0",
                    "protovers": "1.1",
                    "psi": "11D50EC8-9C50-4C32-A658-1CC041C2121C",
                    "srcvers": "600.8.41",
                    "tsid": "74F90143-03B1-5656-A7C7-9E1E5230FE13",
                    "tsm": "0",
                    "vv": "2",
                ],
                type: "_airplay._tcp."
            ),
            .init(
                domain: nil,
                hostname: "Living-Room.local.",
                addresses: ["192.168.0.184"],
                name: "Living Room",
                port: 49152,
                data: [
                    "rpAD": "13b821643395",
                    "rpBA": "9F:46:6D:28:4C:F9",
                    "rpFl": "0x62792",
                    "rpHA": "850b6da0d2d5",
                    "rpHI": "ab9175ac37e5",
                    "rpHN": "61e34c44b463",
                    "rpMac": "2",
                    "rpMd": "AudioAccessory1,1",
                    "rpVr": "320.2",
                ],
                type: "_companion-link._tcp."
            ),
            .init(
                domain: nil,
                hostname: "Living-Room.local.",
                addresses: ["192.168.0.184"],
                name: "07ECBF16-867A-5F4C-BA86-286ED78DDE3A",
                port: 58779,
                data: [
                    "si": "C612333E-2CA4-48DE-BD5C-2DFA626DA330",
                ],
                type: "_homekit._tcp."
            ),
            .init(
                domain: nil,
                hostname: "ff5fbb76-e40c-4635-91ff-6f2648250675.local.",
                addresses: ["192.168.0.184"],
                name: "C3E72D96-F32A-4F3E-BFDD-EB5E3A89CB21",
                port: 319,
                data: [
                    "did": "C3E72D96-F32A-4F3E-BFDD-EB5E3A89CB21",
                    "tsid": "74F90143-03B1-5656-A7C7-9E1E5230FE13",
                ],
                type: "_ieee1588._udp."
            ),
            .init(
                domain: nil,
                hostname: "Living-Room.local.",
                addresses: ["192.168.0.184"],
                name: "D4909CF14A4B@Living Room",
                port: 7000,
                data: [
                    "am": "AudioAccessory1,1",
                    "cn": "0,1,2,3",
                    "da": "true",
                    "et": "0,3,5",
                    "ft": "0x4A7FCA00,0xBC356BD0",
                    "md": "0,1,2",
                    "ov": "15.2",
                    "pk": "a8a2e73f79e61e6948a3de650b88e2b7c4914e5675c516b55d26ba3857e0b3f0",
                    "sf": "0x1a404",
                    "tp": "UDP",
                    "vn": "65537",
                    "vs": "600.8.41",
                    "vv": "2",
                ],
                type: "_raop._tcp."
            ),
            .init(
                domain: nil,
                hostname: "Living-Room.local.",
                addresses: ["192.168.0.184"],
                name: "70-35-60-63.1 Living Room",
                port: 59896,
                data: [:],
                type: "_sleep-proxy._udp."
            ),
            .init(
                domain: nil,
                hostname: "233464f1-7d37-1e55-41da-a39a9becffca.local.",
                addresses: ["192.168.0.162"],
                name: "Google-Nest-Hub-233464f17d371e5541daa39a9becffca",
                port: 8009,
                data: [
                    "bs": "FA8FCA739D87",
                    "ca": "233989",
                    "cd": "852650B647964B1DF86BF00C0F0E2D57",
                    "fn": "Nest Hub",
                    "ic": "/setup/icon.png",
                    "id": "233464f17d371e5541daa39a9becffca",
                    "md": "Google Nest Hub",
                    "nf": "1",
                    "rm": "B14BF278BCE57559",
                    "rs": "",
                    "st": "0",
                    "ve": "05",
                ],
                type: "_googlecast._tcp."
            ),
            .init(
                domain: nil,
                hostname: "Sonos-7828CA831A30.local.",
                addresses: ["192.168.0.188"],
                name: "Bedroom Speaker",
                port: 7000,
                data: [
                    "acl": "0",
                    "deviceid": "78:28:CA:83:1A:30",
                    "features": "0x445F8A00,0x1C340",
                    "flags": "0x4",
                    "fv": "p20.66.4-23300",
                    "gcgl": "0",
                    "gid": "78:28:CA:83:1A:30",
                    "manufacturer": "Sonos",
                    "model": "Table lamp",
                    "pi": "78:28:CA:83:1A:30",
                    "pk": "f531ccfe2cea4354edb260bec740921180a243eaf5c3714e6b548294100f5d42",
                    "protovers": "1.1",
                    "rsf": "0x0",
                    "serialNumber": "78-28-CA-83-1A-30:G",
                    "srcvers": "366.0",
                ],
                type: "_airplay._tcp."
            ),
            .init(
                domain: nil,
                hostname: "Sonos-7828CA831A30.local.",
                addresses: ["192.168.0.188"],
                name: "7828CA831A30@Bedroom Speaker",
                port: 7000,
                data: [
                    "am": "Table lamp",
                    "cn": "0,1",
                    "da": "true",
                    "et": "0,4",
                    "ft": "0x445F8A00,0x1C340",
                    "fv": "p20.66.4-23300",
                    "md": "0,1,2",
                    "pk": "f531ccfe2cea4354edb260bec740921180a243eaf5c3714e6b548294100f5d42",
                    "sf": "0x4",
                    "tp": "UDP",
                    "vn": "65537",
                    "vs": "366.0",
                ],
                type: "_raop._tcp."
            ),
            .init(
                domain: nil,
                hostname: "Sonos-7828CA831A30.local.",
                addresses: ["192.168.0.188"],
                name: "Sonos-7828CA831A30@Bedroom Speaker",
                port: 1443,
                data: [
                    "bootseq": "18",
                    "hhid": "Sonos_9aoZpH18Umh54SjdrjhjIJesdb",
                    "hhsslport": "1843",
                    "info": "/api/v1/players/RINCON_7828CA831A3001400/info",
                    "location": "http://192.168.0.188:1400/xml/device_description.xml",
                    "mdnssequence": "0",
                    "mhhid": "Sonos_9aoZpH18Umh54SjdrjhjIJesdb.9IKKtGV0A6zpjw-Snzzy",
                    "protovers": "1.26.3",
                    "sslport": "1443",
                    "variant": "0",
                    "vers": "3",
                ],
                type: "_sonos._tcp."
            ),
            .init(
                domain: nil,
                hostname: "Sonos-7828CA831A30.local.",
                addresses: ["192.168.0.188"],
                name: "sonos7828CA831A30",
                port: 1400,
                data: [
                    "CPath": "/spotifyzc",
                    "VERSION": "1",
                ],
                type: "_spotify-connect._tcp."
            ),
            .init(
                domain: nil,
                hostname: "macbook-pro.local.",
                addresses: ["192.168.0.189"],
                name: "macbook-pro",
                port: 22,
                data: [:],
                type: "_sftp-ssh._tcp."
            ),
            .init(
                domain: nil,
                hostname: "macbook-pro.local.",
                addresses: ["192.168.0.189"],
                name: "macbook-pro",
                port: 22,
                data: [:],
                type: "_ssh._tcp."
            ),
            .init(
                domain: nil,
                hostname: "wemo_mini-2.local.",
                addresses: ["192.168.0.161"],
                name: "Christmas Tree",
                port: 36859,
                data: [
                    "c#": "4",
                    "ci": "7",
                    "ff": "2",
                    "id": "AA:12:34:D9:BA:28",
                    "md": "Wemo Mini",
                    "pv": "1.1",
                    "s#": "7",
                    "sf": "0",
                    "sh": "S0Celw==",
                ],
                type: "_hap._tcp."
            ),
            .init(
                domain: nil,
                hostname: "wemo_mini-2.local.",
                addresses: ["192.168.0.161"],
                name: "\"OpenWrt SSH\" (2)",
                port: 22,
                data: [
                    "": "OpenWrt SSH server",
                ],
                type: "_ssh._tcp."
            ),
            .init(
                domain: nil,
                hostname: "wemo_mini-4.local.",
                addresses: ["192.168.0.148"],
                name: "Humidifier",
                port: 34204,
                data: [
                    "c#": "3",
                    "ci": "7",
                    "ff": "2",
                    "id": "2C:AB:31:4B:55:83",
                    "md": "Wemo Mini",
                    "pv": "1.1",
                    "s#": "1",
                    "sf": "0",
                    "sh": "Lm8SIw==",
                ],
                type: "_hap._tcp."
            ),
        ]
        super.init()
    }

    func start() {
        delegate?.serviceBrowser(self, didChangeServices: services)
    }

    func stop() {
        delegate?.serviceBrowser(self, didChangeServices: [])
    }

    func reset() {
        delegate?.serviceBrowser(self, didChangeServices: services)
    }
}
