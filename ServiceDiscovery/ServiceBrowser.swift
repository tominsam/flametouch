// Copyright 2015 Thomas Insam. All rights reserved.

import Foundation
import UIKit

protocol ServiceBrowserDelegate: NSObjectProtocol {
    @MainActor
    func serviceBrowser(didChangeServices services: Set<Service>)
}

protocol ServiceBrowser: NSObjectProtocol {
    var delegate: ServiceBrowserDelegate? { get set }

    func start()
    func pause(completion: @MainActor @escaping () -> Void)
    func stop(completion: @MainActor @escaping () -> Void)
}

extension ServiceBrowser {
    func stop() async {
        await withCheckedContinuation { stop(completion: $0.resume) }
    }

    func pause() async {
        await withCheckedContinuation { pause(completion: $0.resume) }
    }
}
