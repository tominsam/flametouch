// Copyright 2019 Thomas Insam. All rights reserved.

import Foundation
import SwiftUI
import SafariServices

// TODO crashes for ssh

public struct SafariViewControllerViewModifier: ViewModifier {
    @State private var url: URL?
    @State private var alert: Bool = false

    public func body(content: Content) -> some View {
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
                default:
                    UIApplication.shared.open(url, options: [:]) { result in
                        if !result {
                            alert = true
                        }
                    }
                }
                return .handled
            })
            .sheet(
                isPresented: $url.asBool(),
                onDismiss: {
                    url = nil
                }, content: {
                    SafariViewRepresentable(url: url!)
                })
            .alert(
                "Can't open URL",
                isPresented: $alert,
                actions: {
                    Button("Ok") {
                        alert = false
                    }
                }, message: {
                    Text("I couldn't open that URL - maybe you need a particular app installed")
                }
            )
    }
}

extension Binding {
    func asBool<Wrapped>() -> Binding<Bool> where Value == Wrapped? {
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
}
