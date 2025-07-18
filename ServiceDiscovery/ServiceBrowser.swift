// Copyright 2015 Thomas Insam. All rights reserved.

import Foundation
import UIKit

protocol ServiceBrowserDelegate: NSObjectProtocol {
    func serviceBrowser(_ serviceBrowser: ServiceBrowser, didChangeServices services: Set<Service>) async
}

protocol ServiceBrowser: NSObjectProtocol {
    var delegate: ServiceBrowserDelegate? { get set }

    func start() async
    func stop() async
    func reset() async
}
