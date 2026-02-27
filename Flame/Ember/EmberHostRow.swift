// Copyright 2016 Thomas Insam. All rights reserved.

import Foundation
import SwiftUI
import UIKit

struct EmberHostRow: View {
    @Environment(\.openURL) private var openURL

    let title: String
    let subtitle: String
    let isAlive: Bool
    let isSelected: Bool
    let url: URL?
    let action: () -> Void

    var body: some View {
        Button(action: action, label: { label })
            .buttonStyle(EmberRowButtonStyle())
    }

    @ViewBuilder
    var label: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(isAlive ? .emberTintHi : .emberTextDim)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.emberCellTitle)
                    .foregroundColor(isAlive && isSelected ? .emberTextHi : .emberTextMid)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.emberCellSubtitle)
                    .foregroundColor(isAlive && isSelected ? .emberTextMid : .emberTextLow)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            //.contextMenu { contextMenu }

            if let url {
                Button(action: {
                    openURL(url)
                }, label: {
                    Text("Open")
                })
                .fixedSize()
                .buttonStyle(.ember)
            } else {
                Image(systemName: "chevron.right")
                    .imageScale(.small)
                    .accessibilityHidden(true)
                    .foregroundColor(.emberTextLow)
                    .rotationEffect(.degrees(isSelected ? 90 : 0))
            }
        }
        .padding([.top, .bottom], 8)
        .frame(minHeight: 40)
    }

    @ViewBuilder
    var contextMenu: some View {
        Button(action: {
            UIPasteboard.general.string = title
        }, label: {
            Label("Copy name", systemImage: "doc.on.clipboard.fill")
        })
        Button(action: {
            UIPasteboard.general.string = subtitle
        }, label: {
            Label("Copy value", systemImage: "doc.on.clipboard")
        })
        if let url {
            Button(action: {
                openURL(url)
            }, label: {
                Label("Open", systemImage: "arrowshape.turn.up.right")
            })
        }
    }

}

#Preview {
    @Previewable @Namespace var selectionBackgroundNamespace
    @Previewable @State var selection: Int = 0

    let url = URL(string: "http://foo.com")
    ScrollView {
        VStack(spacing: 0) {
            EmberHostRow(title: "Title", subtitle: "Subtitle", isAlive: true, isSelected: false, url: nil, action: {})
            EmberHostRow(title: "Selected", subtitle: "Subtitle", isAlive: true, isSelected: true, url: nil, action: {})
            EmberHostRow(title: "Dead", subtitle: "Subtitle", isAlive: false, isSelected: false, url: nil, action: {})
            EmberHostRow(title: "With URL", subtitle: "Subtitle", isAlive: true, isSelected: false, url: url, action: {})
        }
    }
    .emberTheme()
}
