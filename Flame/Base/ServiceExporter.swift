// Copyright 2021 Thomas Insam. All rights reserved.

import UIKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Synchronization

// Converts the MainActor serviceController into a read-only nonisolated hosts lists for the exporter
private final class ClusterTracker: Sendable {
    let serviceController: ServiceController
    let hostsMutex: Mutex<[Host]> = .init([])
    
    init(serviceController: ServiceController) {
        self.serviceController = serviceController
        watch()
    }
    
    func watch() {
        withObservationTracking {
            MainActor.assumeIsolated { // serviceController is mainactor
                self.hostsMutex.withLock { $0 = serviceController.clusters }
            }
        } onChange: { [weak self] in
            self?.watch()
        }
    }
    
    var hosts: [Host] {
        hostsMutex.withLock(\.self)
    }
}

struct ExportServicesDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]
    
    private let tracker: ClusterTracker

    init(serviceController: ServiceController) {
        self.tracker = ClusterTracker(serviceController: serviceController)
    }
    
    init(configuration: ReadConfiguration) throws {
        fatalError()
    }
    
    func getData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: try getData())
    }
    
    
}

extension ExportServicesDocument: Transferable {

    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    static var decoder: JSONDecoder {
        JSONDecoder()
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json, encoder: encoder, decoder: decoder)
            .suggestedFileName("flame-export.json")
    }
}

extension ExportServicesDocument: Codable {
    enum CodingKeys: String, CodingKey {
        case hosts
    }

    init(from decoder: any Decoder) throws {
        fatalError()
    }

    public func encode(to encoder: any Encoder) throws {
        nonisolated(unsafe)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tracker.hosts, forKey: .hosts)
    }
}

extension Host: Encodable {
    enum CodingKeys: String, CodingKey {
        case addresses, services, name
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(services, forKey: .services)
        try container.encode(addressCluster.sorted, forKey: .addresses)
    }
}

extension Service: Encodable {
    enum CodingKeys: String, CodingKey {
        case name, type, domain, port, data
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(domain, forKey: .domain)
        try container.encode(port, forKey: .port)
        try container.encode(data, forKey: .data)
    }

}
