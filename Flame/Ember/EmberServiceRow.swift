// Copyright 2016 Thomas Insam. All rights reserved.

import Foundation
import SwiftUI
import UIKit

struct EmberServiceRow: View {
    @Environment(\.openURL) private var openURL

    let title: String
    let subtitle: String?
    let url: URL?

    var body: some View {
        HStack {
            Text(title)
                .font(.emberMeta)
                .foregroundColor(.emberTextLow)
                .lineLimit(1)
            Spacer()
            if let subtitle {
                Text(subtitle)
                    .font(.emberMeta)
                    .foregroundColor(url != nil ? .accentColor : .emberTextMid)
                    .lineLimit(1)
            }
        }
        .padding([.top, .bottom], 8)
        .frame(minHeight: 44)
        .overlay {
            Menu(content: {
                if subtitle != nil {
                    Section(title) {
                        Button(action: {
                            UIPasteboard.general.string = title
                        }, label: {
                            Label("Copy name", systemImage: "doc.on.clipboard.fill")
                        })
                    }
                }
                Section(subtitle ?? title) {
                    Button(action: {
                        UIPasteboard.general.string = subtitle ?? title
                    }, label: {
                        Label("Copy value", systemImage: "doc.on.clipboard")
                    })
                }
                if let url {
                    Button(action: {
                        openURL(url)
                    }, label: {
                        Label("Open", systemImage: "arrowshape.turn.up.right")
                    })
                }
            }, label: {
                Color(.clear)
            })
        }
    }
}

#Preview {
    @Previewable @Namespace var selectionBackgroundNamespace
    @Previewable @State var selection: Int = 0

    let url = URL(string: "http://foo.com")
    ScrollView {
        VStack(spacing: 16) {
            Text("Value Cell").font(.emberSectionHeader)
            EmberServiceRow(title: "Title", subtitle: nil, url: nil)
            EmberServiceRow(title: "Title", subtitle: "Subtitle", url: nil)
            EmberServiceRow(title: "Title", subtitle: "Subtitle", url: url)
        }
    }
    .emberTheme()
}
