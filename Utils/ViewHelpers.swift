// Copyright 2015 Thomas Insam. All rights reserved.

import Foundation
import SwiftUI

public extension View {
    @ViewBuilder
    func ifNonNil<Content: View, T>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }

    @ViewBuilder
    func ifiOS<Content: View>(transform: (Self) -> Content) -> some View {
        #if targetEnvironment(macCatalyst)
            self
        #else
            transform(self)
        #endif
    }
}
