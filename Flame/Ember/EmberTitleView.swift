// Copyright 2016 Thomas Insam. All rights reserved.

import SwiftUI
import UIKit
import Flow

struct EmberTitleView: View {
    let title: String
    let subTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.emberHeading)
                .foregroundStyle(.emberTextHi)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
                .fixedSize(horizontal: true, vertical: true)

            Text(subTitle)
                .font(.emberSectionHeader)
                .textCase(.uppercase)
                .foregroundStyle(.emberTextLow)
                .fixedSize(horizontal: true, vertical: true)
        }
        .frame(alignment: .leading)
    }
}
