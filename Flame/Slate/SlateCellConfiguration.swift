// Copyright 2016 Thomas Insam. All rights reserved.

import Foundation
import SwiftUI
import UIKit

public struct SlateValueCell: View {
    @Environment(\.openURL) private var openURL

    let title: String
    let subtitle: String?
    let url: URL?

    public init(
        title: String,
        subtitle: String?,
        url: URL? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.url = url
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
                    openURL(url)
                }, label: {
                    Label("Open", systemImage: "arrowshape.turn.up.right")
                })
            }
        }
        .ifNonNil(url) { view, url in
            view.onTapGesture {
                openURL(url)
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

public struct SlateDetailCell: View {
    @Environment(\.openURL) private var openURL

    let title: String
    let subtitle: String
    let copyLabel: String
    let openable: ServiceNamer.OpenableService?

    init(
        title: String,
        subtitle: String,
        copyLabel: String,
        openable: ServiceNamer.OpenableService? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.copyLabel = copyLabel
        self.openable = openable
    }

    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.standard)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Label(subtitle, systemImage: openable?.icon ?? "")
                    .labelStyle(SlateSmallTrailingIcon())
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
            if let openable {
                Button(action: {
                    openURL(openable.url)
                }, label: {
                    Label(openable.action, systemImage: openable.icon)
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

struct SlateSmallTrailingIcon: LabelStyle {
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
            SlateValueCell(title: "Title", subtitle: nil)
            SlateValueCell(title: "Title", subtitle: "Subtitle")
            SlateValueCell(title: "Title", subtitle: "Subtitle", url: url)
        }
        Section("Detail Cell") {
            SlateDetailCell(title: "Title", subtitle: "Subtitle", copyLabel: "test")
            SlateDetailCell(
                title: "Title",
                subtitle: "Subtitle",
                copyLabel: "test",
                openable: ServiceNamer.OpenableService(Service(name: "Demo", type: "_http._tcp", domain: nil, addressCluster: .from(addresses: [], hostnames: []), port: 0, data: [:], lastSeen: .now, alive: true))
            )
        }
    }.tint(.red)
}
