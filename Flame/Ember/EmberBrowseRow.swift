// Copyright 2016 Thomas Insam. All rights reserved.

import Foundation
import SwiftUI
import UIKit

struct EmberBrowseRow: View {
    @Environment(\.openURL) private var openURL

    let title: String
    let subtitle: String
    let copyLabel: String
    let openableService: Service?
    let isSelected: Bool
    let selectionBackgroundNamespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action, label: { content })
            .buttonStyle(EmberRowButtonStyle())
    }

    var content: some View {
        label
            .background {
                if isSelected {
                    FilledStrokedRoundRect(
                        fill: .emberTintDim,
                        stroke: .emberTintHi,
                        radius: 8
                    )
                    .opacity(0.3)
                    .padding(-8)
                    .matchedGeometryEffect(id: "background", in: selectionBackgroundNamespace)
                    .transition(.scale(scale: 1))
                }
            }
            .contextMenu { menu }
            .accessibilityElement(children: .combine)
            .accessibilityHint("Double tap to open details")
            .accessibilityAction(named: "Copy name") {
                UIPasteboard.general.string = title
            }
            .accessibilityAction(named: copyLabel) {
                UIPasteboard.general.string = subtitle
            }
    }

    var label: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.emberCellTitle)
                    .foregroundColor(.emberTextHi)
                    .lineLimit(1)
                Label(subtitle, systemImage: openableService?.url == nil ? "" : "globe")
                    .labelStyle(SmallTrailingIcon())
                    .font(.emberMeta)
                    .foregroundColor(.emberTextMid)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .imageScale(.small)
                .accessibilityHidden(true)
                .foregroundColor(.emberTextLow)
        }

    }

    var menu: some View {
        Group {
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
    }
}

struct EmberRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(.rect)
    }
}

private struct SmallTrailingIcon: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon.imageScale(.small)
        }
    }
}

#Preview {
    @Previewable @Namespace var selectionBackgroundNamespace
    @Previewable @State var selection: Int = 0

    VStack(spacing: 0) {
        EmberBrowseRow(
            title: "Title",
            subtitle: "Subtitle",
            copyLabel: "test",
            openableService: nil,
            isSelected: selection == 0,
            selectionBackgroundNamespace: selectionBackgroundNamespace,
            action: { selection = 0 },
        )
        EmberBrowseRow(
            title: "Title",
            subtitle: "Subtitle",
            copyLabel: "test",
            openableService: Service(name: "Demo", type: "_http._tcp", domain: nil, addressCluster: .from(addresses: [], hostnames: []), port: 0, data: [:], lastSeen: .now, alive: true),
            isSelected: selection == 1,
            selectionBackgroundNamespace: selectionBackgroundNamespace,
            action: { selection = 1 },
        )
    }
    .emberTheme()
}

