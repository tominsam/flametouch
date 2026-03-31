// Copyright 2016 Thomas Insam. All rights reserved.

import Foundation
import SwiftUI
import UIKit

struct EmberBrowseRow: View {
    @Environment(\.openURL) private var openURL

    let title: String
    let subtitle: String
    let copyLabel: String
    let hostIcon: String
    let openable: ServiceNamer.OpenableService?
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
        HStack(spacing: 12) {
            Image(systemName: hostIcon)
                .font(.title3)
                .foregroundColor(isSelected ? .emberTintHi : .emberTextLow)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.emberCellTitle)
                    .foregroundColor(isSelected ? .emberTextHi : .emberTextMid)
                    .lineLimit(1)
                Label(subtitle, systemImage: openable?.icon ?? "")
                    .labelStyle(SmallTrailingIcon())
                    .font(.emberMeta)
                    .foregroundColor(isSelected ? .emberTextMid : .emberTextLow)
                    .lineLimit(1)
                    .truncationMode(.middle)
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
            if let openable {
                Button(action: {
                    openURL(openable.url)
                }, label: {
                    Label(openable.action, systemImage: openable.icon)
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
            title: "Generic Host",
            subtitle: "192.168.1.1 • 3 services",
            copyLabel: "test",
            hostIcon: "desktopcomputer",
            openable: nil,
            isSelected: selection == 0,
            selectionBackgroundNamespace: selectionBackgroundNamespace,
            action: { selection = 0 },
        )
        EmberBrowseRow(
            title: "Apple TV",
            subtitle: "192.168.1.2 • 5 services",
            copyLabel: "test",
            hostIcon: "airplayvideo",
            openable: ServiceNamer.OpenableService(Service(name: "Demo", type: "_http._tcp", domain: nil, addressCluster: .from(addresses: [], hostnames: []), port: 0, data: [:], lastSeen: .now, alive: true)),
            isSelected: selection == 1,
            selectionBackgroundNamespace: selectionBackgroundNamespace,
            action: { selection = 1 },
        )
        EmberBrowseRow(
            title: "Printer",
            subtitle: "192.168.1.3 • 2 services",
            copyLabel: "test",
            hostIcon: "printer",
            openable: nil,
            isSelected: selection == 2,
            selectionBackgroundNamespace: selectionBackgroundNamespace,
            action: { selection = 2 },
        )
    }
    .emberTheme()
}

