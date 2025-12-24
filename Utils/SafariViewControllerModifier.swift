// Copyright 2019 Thomas Insam. All rights reserved.

import Foundation
import SwiftUI
import SafariServices

// TODO crashes for ssh

public struct SafariViewControllerViewModifier: ViewModifier {
    @State private var url: URL?

    public func body(content: Content) -> some View {
#if targetEnvironment(macCatalyst)
        content
#else
        content
            .environment(\.openURL, OpenURLAction { url in
                switch url.scheme {
                case "http", "https":
                    // If there's a universal link handler for this URL, use that for preference
                    UIApplication.shared.open(url, options: [.universalLinksOnly: true]) { result in
                        if !result {
                            self.url = url
                        }
                    }
                    return .handled
                default:
                    return .systemAction
                }
            })
            .fullScreenCover(
                isPresented: $url.asBool(),
                onDismiss: {
                    url = nil
                }, content: {
                    SafariViewRepresentable(url: url!)
                })
#endif
    }
}

extension Binding {
    func asBool<Wrapped>() -> Binding<Bool> where Value == Wrapped?, Value: Sendable {
        Binding<Bool>(
            get: {
                wrappedValue != nil
            },
            set: { newValue in
                if newValue == false {
                    wrappedValue = nil
                }
            }
        )
    }
}

struct SafariViewRepresentable: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<Self>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariViewRepresentable>) {
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiViewController: SFSafariViewController, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? .greatestFiniteMagnitude, height: proposal.height ?? .greatestFiniteMagnitude)
    }
}
