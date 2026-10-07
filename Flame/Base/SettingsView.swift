// Copyright 2016 Thomas Insam. All rights reserved.

import SwiftUI
import UIKit

struct SettingsView: View {
    static let hideMatterDevicesKey = "hideMatterDevices"

    @Environment(\.dismiss) private var dismiss
    @AppStorage(hideMatterDevicesKey) var hideMatterDevices = false

    var body: some View {
        Form {
            Section {
                aboutHeader
                    .listRowBackground(Color.clear)
            } footer: {
                quote
                    .padding(.top, 24)
            }

            Section {
                LabeledContent("Version", value: version)
                Link(destination: URL(string: "https://movieos.org/code/flame/")!) {
                    Label("movieos.org/code/flame", systemImage: "safari")
                }
            }
            .listRowBackground(Color.emberInset)

            Section {
                Toggle("Hide Matter devices", isOn: $hideMatterDevices)
            } footer: {
                Text("Hides accessories that only advertise Matter. Hubs and speakers that also support Matter are still shown.")
                    .foregroundStyle(.emberTextLow)
            }
            .listRowBackground(Color.emberInset)
            .padding(.bottom, 16)

        }
        .background(.emberBase)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .close) {
                    dismiss()
                }
            }
        }
    }

    var aboutHeader: some View {
        VStack(spacing: 16) {
            Image("Icon_160")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 96)
                .cornerRadius(20)

            Text("A Bonjour Network Services Browser by [Tom Insam](https://movieos.org), built on previous work by [Sven‑S. Porst](http://earthlingsoft.net/ssp/), [Paul Mison](http://husk.org/) and [Tom Insam](https://movieos.org/).")
                .font(.emberCellSubtitle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    var quote: some View {
        VStack(spacing: 8) {
            Text(verbatim:
                    "She had fortunately always her appetite for news. The pure flame of the " +
                 "disinterested burned in her cave of treasures as a lamp in a Byzantine vault."
            )
            .italic()

            // Don't want to translate this, gotta jump through these hoops to still get markdown
            if let attributed = try? AttributedString(markdown: "— Henry James, _The Ambassadors_") {
                Text(attributed)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .font(.emberCellSubtitle)
        .foregroundStyle(.emberTextLow)
    }

    var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }
}

#Preview {
    SettingsView()
        .emberTheme()
}
