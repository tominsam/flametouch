// Copyright 2020 Thomas Insam. All rights reserved.

import UIKit

// bwahahahah so unsafe
extension NetService: @unchecked @retroactive Sendable {}

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
    @concurrent nonisolated
    var stringAddresses: Set<String> {
        get async {
            // self.addresses is expensive
            assert(!Thread.isMainThread)
            return Set((addresses ?? []).compactMap { getIFAddress($0) })
        }
    }
}

// Get the local ip addresses used by this node
// "The NSData object [..] contains an appropriate sockaddr structure that you can
// use to connect to the socket. The exact type of this structure depends on the
// service to which you are connecting."
nonisolated
private func getIFAddress(_ data: Data) -> String? {
    let string = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> String? in
        let family = bytes.withMemoryRebound(to: sockaddr.self) { sa -> Int32 in
            Int32(sa.first?.sa_family ?? -0)
        }
        switch family {
        case AF_INET:
            return bytes.withMemoryRebound(to: sockaddr_in.self) { sa -> String? in
                guard var addr = sa.first?.sin_addr else { return nil }
                let size = Int(INET_ADDRSTRLEN)
                return withUnsafeTemporaryAllocation(of: Int8.self, capacity: size) { buffer -> String? in
                    if let cString = inet_ntop(family, &addr, buffer.baseAddress, socklen_t(size)) {
                        return String(cString: cString)
                    } else {
                        ELog("inet_ntop errno \(errno) from \(data)")
                        return nil
                    }
                }
            }
        case AF_INET6:
            return bytes.withMemoryRebound(to: sockaddr_in6.self) { sa -> String? in
                guard var addr = sa.first?.sin6_addr else { return nil }
                let size = Int(INET6_ADDRSTRLEN)
                return withUnsafeTemporaryAllocation(of: Int8.self, capacity: size) { buffer -> String? in
                    if let cString = inet_ntop(family, &addr, buffer.baseAddress, socklen_t(size)) {
                        return String(cString: cString)
                    } else {
                        ELog("inet_ntop errno \(errno) from \(data)")
                        return nil
                    }
                }
            }
        default:
            ELog("unknown family \(family)")
            return nil
        }
    }

    guard let string else { return nil }

    // link local addresses don't count
    if string.hasPrefix("fe80:") || string.hasPrefix("127.") || string == "::1" {
        return nil
    }

    return string
}

extension Data {
    var hex: String {
        map { byte in String(format: "%02X", byte) }.joined()
    }
}
