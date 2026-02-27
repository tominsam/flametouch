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

struct FilledStrokedRoundRect<FillStyle: ShapeStyle, StrokeStyle: ShapeStyle>: View {
    let fill: FillStyle
    let stroke: StrokeStyle
    let radius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .stroke(stroke, lineWidth: 2)
            .background(
                RoundedRectangle(cornerRadius: radius).fill(fill)
            )
    }
}
