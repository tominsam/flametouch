// Copyright 2015 Thomas Insam. All rights reserved.

import SwiftUI
import UIKit

extension Font {
    static let legible: Font = {
        var descriptor = UIFont.preferredFont(forTextStyle: .body).fontDescriptor
        descriptor = descriptor.addingAttributes([
            .featureSettings: [[
                UIFontDescriptor.FeatureKey.type: kStylisticAlternativesType,
                UIFontDescriptor.FeatureKey.selector: kStylisticAltSixOnSelector,
            ]],
        ])
        let uiFont = UIFont(descriptor: descriptor, size: 0)
        return Font(uiFont)
    }()

    static let standard: Font = {
        var descriptor = UIFont.preferredFont(forTextStyle: .body).fontDescriptor
        let uiFont = UIFont(descriptor: descriptor, size: 0)
        return Font(uiFont)
    }()
}
