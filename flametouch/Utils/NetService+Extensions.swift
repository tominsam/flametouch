// Copyright 2020 Thomas Insam. All rights reserved.

import UIKit

extension NetService {

    private var txtData: [(key: String, value: String)] {

        guard let txtRecord = txtRecordData(), !txtRecord.isEmpty else {
            return []
        }

        // https://github.com/lapcat/Bonjeff/commit/d275d79d5de1ac918965c25932e72f0485ac3e98
        let dict = CFNetServiceCreateDictionaryWithTXTData(nil, txtRecord as CFData)?
            .takeRetainedValue() as? [String: Data]
            ?? ["": txtRecord]

        var txtData = [(key: String, value: String)]()
        for (key, value) in dict {
            if let stringValue = String(bytes: value, encoding: .utf8) {
                txtData.append((key: key, value: stringValue))
            } else {
                txtData.append((key: key, value: value.hex))
            }
        }
        return txtData.sorted { $0.key.lowercased() < $1.key.lowercased() }
    }

    var txtDict: [String: String] {
        Dictionary(txtData, uniquingKeysWith: { first, _ in first })
    }

    /// network addresses of the service as strings, sorted by shortest first (which will prioritize IPv4)
    var stringAddresses: Set<String> {
        return Set((addresses ?? []).compactMap { getIFAddress($0) })
    }

}

// Get the local ip addresses used by this node
private func getIFAddress(_ data: Data) -> String? {

    let hostname = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET6_ADDRSTRLEN))
    defer {
        hostname.deinitialize(count: Int(INET6_ADDRSTRLEN))
    }

    var _ = getnameinfo(
        (data as NSData).bytes.bindMemory(to: sockaddr.self, capacity: data.count),
        socklen_t(data.count),
        hostname,
        socklen_t(INET6_ADDRSTRLEN),
        nil,
        0,
        NI_NUMERICHOST)

    let string = String(cString: hostname)

    // link local addresses don't cound
    if string.hasPrefix("fe80:") || string.hasPrefix("127.") || string == "::1" {
        return nil
    }

    return string
}
