// Copyright 2016 Thomas Insam. All rights reserved.

import Foundation
import SwiftUI
import UIKit

func bodyFont(legible: Bool) -> Font {
    var descriptor = UIFont.preferredFont(forTextStyle: .body).fontDescriptor
    if legible {
        descriptor = descriptor.addingAttributes([
            .featureSettings: [[
                UIFontDescriptor.FeatureKey.type: kStylisticAlternativesType,
                UIFontDescriptor.FeatureKey.selector: kStylisticAltSixOnSelector,
            ]],
        ])
    }
    let uiFont = UIFont(descriptor: descriptor, size: 0)
    return Font(uiFont)
}

public struct ValueCell: View {
    let title: String
    let subtitle: String?
    let url: URL?
    let tapAction: (URL) -> Void

    public init(
        title: String,
        subtitle: String?,
        url: URL? = nil,
        tapAction: @escaping (URL) -> Void = { _ in }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.url = url
        self.tapAction = tapAction
    }

    public var body: some View {
        HStack {
            Text(title)
                .font(bodyFont(legible: subtitle == nil))
                .foregroundColor(.primary)
                .lineLimit(1)
            Spacer()
            if let subtitle {
                Text(subtitle)
                    .font(bodyFont(legible: true))
                    .foregroundColor(url != nil ? .accentColor : .secondary)
                    .lineLimit(1)
            }
        }
        .padding([.top, .bottom], 8)
        .frame(minHeight: 40)
        .contextMenu {
            if subtitle != nil {
                Button(action: {
                    UIPasteboard.general.string = title
                }, label: {
                    Label("Copy name", systemImage: "doc.on.clipboard.fill")
                })
            }
            Button(action: {
                UIPasteboard.general.string = subtitle ?? title
            }, label: {
                Label("Copy value", systemImage: "doc.on.clipboard")
            })
            if let url {
                Button(action: {
                    tapAction(url)
                }, label: {
                    Label("Open", systemImage: "arrowshape.turn.up.right")
                })
            }
        }
        .ifNonNil(url) { view, url in
            view.onTapGesture {
                tapAction(url)
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Double tap to open URL")
        }
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: "Copy name") {
            UIPasteboard.general.string = title
        }
    }
}

public struct DetailCell: View {
    let title: String
    let subtitle: String
    let copyLabel: String
    let url: URL?

    public init(
        title: String,
        subtitle: String,
        copyLabel: String,
        url: URL? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.copyLabel = copyLabel
        self.url = url
    }

    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(bodyFont(legible: false))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Label(subtitle, systemImage: url == nil ? "" : "globe")
                    .labelStyle(SmallTrailingIcon())
                    .font(bodyFont(legible: true))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .accessibilityHidden(true)
                .foregroundColor(.secondary)
        }
        .padding([.top, .bottom], 4)
        .contextMenu {
            Button(action: {
                UIPasteboard.general.string = title
            }, label: {
                Label("Copy name", systemImage: "doc.on.clipboard.fill")
            })
            Button(action: {
                UIPasteboard.general.string = subtitle
            }, label: {
                Label(copyLabel, systemImage: "doc.on.clipboard")
            })
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double tap to open details")
        .accessibilityAction(named: "Copy name") {
            UIPasteboard.general.string = title
        }
        .accessibilityAction(named: copyLabel) {
            UIPasteboard.general.string = subtitle
        }
    }
}

public extension View {
    @ViewBuilder
    func ifNonNil<Content: View, T>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }

    @ViewBuilder
    func ifiOS<Content: View>(transform: (Self) -> Content) -> some View {
        #if targetEnvironment(macCatalyst)
            self
        #else
            transform(self)
        #endif
    }
}

struct SmallTrailingIcon: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon.imageScale(.small)
        }
    }
}

#Preview {
    let url = URL(string: "http://foo.com")
    return List {
        Section("Value Cell") {
            ValueCell(title: "Title", subtitle: nil)
            ValueCell(title: "Title", subtitle: "Subtitle")
            ValueCell(title: "Title", subtitle: "Subtitle", url: url)
        }
        Section("Detail Cell") {
            DetailCell(title: "Title", subtitle: "Subtitle", copyLabel: "test")
            DetailCell(title: "Title", subtitle: "Subtitle", copyLabel: "test", url: url)
        }
    }.tint(.red)
}
