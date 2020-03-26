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
        let foreground: UIColor = .dynamic(light: .label, dark: .white)
        let icon: UIColor = .dynamic(light: .systemRed, dark: .systemRed)
        let background: UIColor = .dynamic(light: .systemGroupedBackground, dark: .systemGroupedBackground)
        #else
        let foreground: UIColor = .dynamic(light: .white, dark: .systemRed)
        let icon: UIColor = .dynamic(light: .white, dark: .systemRed)
        let background: UIColor = .dynamic(light: .red, dark: .systemBackground)
        #endif

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.shadowImage = nil
        appearance.shadowColor = nil
        appearance.backgroundColor = background
        appearance.titleTextAttributes = [
            .foregroundColor: foreground
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: foreground
        ]

        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: icon
        ]
        appearance.buttonAppearance = buttonAppearance
        navigationBar.compactAppearance = nil
        navigationBar.scrollEdgeAppearance = nil
        navigationBar.standardAppearance = appearance
        navigationBar.tintColor = icon
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
