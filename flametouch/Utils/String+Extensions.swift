// Copyright 2019 Thomas Insam. All rights reserved.

import Foundation

extension String {
    func widont() -> String {
        let lastSpace = self.range(of: " ", options: .backwards, range: nil, locale: nil)
        if let last = lastSpace {
            return self.replacingCharacters(in: last, with: "\u{00A0}")
        }
        return self
    }
}
