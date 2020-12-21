//
//  NetService+Extensions.swift
//  Flame
//
//  Created by Thomas Insam on 7/1/20.
//  Copyright © 2020 tominsam. All rights reserved.
//

import UIKit

extension NetService {

    var txtData: [(key: String, value: String)] {
        var txtData = [(key: String, value: String)]()

        if let txtRecord = txtRecordData() {

            // https://github.com/lapcat/Bonjeff/commit/d275d79d5de1ac918965c25932e72f0485ac3e98
            let dict = CFNetServiceCreateDictionaryWithTXTData(nil, txtRecord as CFData)?
                .takeRetainedValue() as? Dictionary<String,Data>
                ?? ["":txtRecord]

            for (key, value) in dict {
                if let stringValue = String(bytes: value, encoding: .utf8) {
                    txtData.append((key: key, value: stringValue))
                } else {
                    txtData.append((key: key, value: value.hex))
                }
            }
        }
        return txtData.sorted { $0.key.lowercased() < $1.key.lowercased() }
    }

    var txtDict: [String: String] {
        Dictionary(txtData, uniquingKeysWith: { first, _ in first })
    }

}
