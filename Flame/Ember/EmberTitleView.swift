// Copyright 2016 Thomas Insam. All rights reserved.

import SwiftUI
import UIKit
import Flow

struct EmberTitleView: View {
    let title: String
    let subTitle: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.emberHeading)
                .foregroundStyle(.emberTextHi)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

            Text(subTitle)
                .font(.emberMeta)
                .textCase(.uppercase)
                .foregroundStyle(.emberTextMid)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)

    }

}
