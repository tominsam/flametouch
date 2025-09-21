// Copyright 2016 Thomas Insam. All rights reserved.

import Foundation
import SwiftUI
import UIKit

extension Font {
    static var legible: Font = {
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

    static var standard: Font = {
        var descriptor = UIFont.preferredFont(forTextStyle: .body).fontDescriptor
        let uiFont = UIFont(descriptor: descriptor, size: 0)
        return Font(uiFont)
    }()
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
                .font(subtitle == nil ? .legible : .standard)
                .foregroundColor(.primary)
                .lineLimit(1)
            Spacer()
            if let subtitle {
                Text(subtitle)
                    .font(.legible)
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
    @Environment(\.openURL) private var openURL

    let title: String
    let subtitle: String
    let copyLabel: String
    let openableService: Service?

    public init(
        title: String,
        subtitle: String,
        copyLabel: String,
        openableService: Service? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.copyLabel = copyLabel
        self.openableService = openableService
    }

    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.standard)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Label(subtitle, systemImage: openableService?.url == nil ? "" : "globe")
                    .labelStyle(SmallTrailingIcon())
                    .font(.legible)
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
            if let openableService, let url = openableService.url {
                Button(action: {
                    openURL(url)
                }, label: {
                    Label(openableService.openAction, systemImage: "globe")
                })
            }
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
    List {
        Section("Value Cell") {
            ValueCell(title: "Title", subtitle: nil)
            ValueCell(title: "Title", subtitle: "Subtitle")
            ValueCell(title: "Title", subtitle: "Subtitle", url: url)
        }
        Section("Detail Cell") {
            DetailCell(title: "Title", subtitle: "Subtitle", copyLabel: "test")
            DetailCell(
                title: "Title",
                subtitle: "Subtitle",
                copyLabel: "test",
                openableService: Service(name: "Demo", type: "_http._tcp", domain: nil, addressCluster: .from(addresses: [], hostnames: []), port: 0, data: [:], lastSeen: .now, alive: true)
            )
        }
    }.tint(.red)
}
