// Copyright 2015 Thomas Insam. All rights reserved.

import Foundation
import UIKit

protocol ServiceBrowser: AnyObject {
    var services: AsyncStream<Set<Service>> { get }
    func start() async
    func pause() async
    func stop() async
}
