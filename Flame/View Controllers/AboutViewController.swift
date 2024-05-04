// Copyright 2016 Thomas Insam. All rights reserved.

import SwiftUI
import UIKit

struct AboutView: View {
    var body: some View {
        ScrollView(.vertical) {
            VStack {
                VStack(spacing: 16) {
                    Spacer()

                    Image("Icon_160")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 120)
                        .cornerRadius(24)

                    Spacer().frame(height: 8)

                    Text(.init(
                        "A Bonjour Network Services Browser by [Tom Insam](https://movieos.org), " +
                            "built on previous work by [Sven‑S. Porst](http://earthlingsoft.net/ssp/), " +
                            "[Paul Mison](http://husk.org/) and [Tom Insam](https://movieos.org/)."
                    ))

                    if let url = URL(string: "https://movieos.org/code/flame/") {
                        Link(destination: url, label: { Text("Visit web page") })
                    }

                    Spacer().frame(height: 8)
                    Divider()
                    Spacer().frame(height: 8)

                    Text(verbatim:
                        "She had fortunately always her appetite for news. The pure flame of the " +
                            "disinterested burned in her cave of treasures as a lamp in a Byzantine vault."
                    )
                    .italic()
                    .padding([.leading, .trailing], 16)

                    // Don't want to translate this, gotta jump through these hoops to still get markdown
                    if let attributed = try? AttributedString(markdown: "— Henry James, _The Ambassadors_") {
                        Text(attributed)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    Spacer()
                    Spacer()
                }
                .lineLimit(nil)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 600)
                .padding([.leading, .trailing], 40)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

class AboutViewController: UIHostingController<AboutView> {
    init() {
        super.init(rootView: AboutView())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func done() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
