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
            for (key, value) in NetService.dictionary(fromTXTRecord: txtRecord) {
                if let stringValue = String(bytes: value, encoding: .utf8) {
                    txtData.append((key: key, value: stringValue))
                } else {
                    txtData.append((key: key, value: value.hex))
                }
            }
        }
        return txtData.sorted { a, b in
            return a.key.lowercased() < b.key.lowercased()
        }
    }

    var txtDict: [String: String] {
        Dictionary(txtData, uniquingKeysWith: { a, b in a })
    }

}
