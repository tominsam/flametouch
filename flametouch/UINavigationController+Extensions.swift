//
//  UINavigationController+Extensions.swift
//  Flame
//
//  Created by tominsam on 7/26/19.
//  Copyright © 2019 tominsam. All rights reserved.
//

import UIKit

extension UINavigationController {
    func theme() {
        #if targetEnvironment(macCatalyst)
        #else
        let foreground: UIColor = .dynamic(light: .white, dark: .systemRed)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.shadowImage = nil
        appearance.shadowColor = nil
        appearance.backgroundColor = .dynamic(light: .red, dark: .systemBackground)
        appearance.titleTextAttributes = [
            .foregroundColor: foreground
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: foreground
        ]

        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: foreground
        ]
        appearance.buttonAppearance = buttonAppearance
        navigationBar.compactAppearance = nil
        navigationBar.scrollEdgeAppearance = nil
        navigationBar.standardAppearance = appearance
        navigationBar.tintColor = foreground
        #endif
    }
}


fileprivate extension UIColor {
    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return dark
            case .light:
                return light
            default:
                return light
            }
        }

    }
}
