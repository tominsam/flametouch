// Copyright 2019 Thomas Insam. All rights reserved.

import ServiceDiscovery
import UIKit
import Utils

class CustomSplitViewController: UISplitViewController {

    // rendered in the secondary vc when we don't have anything else to put there
    private lazy var emptyViewController = with(UIViewController()) {
        $0.view.backgroundColor = .systemGroupedBackground
    }

    init(primaryViewController: UIViewController) {
        super.init(style: .doubleColumn)
        super.delegate = self
        preferredSplitBehavior = .tile
        preferredDisplayMode = .oneBesideSecondary
        primaryBackgroundStyle = .sidebar
        maximumPrimaryColumnWidth = 640
        minimumPrimaryColumnWidth = 320
        preferredPrimaryColumnWidthFraction = 0.35
        primaryBackgroundStyle = .none // Or .sidebar but I hate it.

        #if !os(visionOS)
        presentsWithGesture = false
        displayModeButtonVisibility = .never
        #endif

        setViewController(StaticNavigationController(rootViewController: primaryViewController), for: .primary)
        setViewController(UINavigationController(rootViewController: emptyViewController), for: .secondary)
        primary.navigationBar.prefersLargeTitles = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // divider color
        view.backgroundColor = .opaqueSeparator
    }

    fileprivate var primary: UINavigationController {
        // swiftlint:disable:next force_cast
        return viewController(for: .primary) as! UINavigationController
    }

    fileprivate var secondary: UINavigationController {
        // swiftlint:disable:next force_cast
        return viewController(for: .secondary) as! UINavigationController
    }

    public func clearSecondaryViewController() {
        secondary.viewControllers = [emptyViewController]
    }

    // Menu action. It's on the split view controller because that's always
    // in the responder chain but still has a window/vc to present from
    // but the actual exporter is on the browser view controller because that's
    // where the list of services is
    @objc
    func saveExportedData() {
        guard let browse = primary.viewControllers.first as? BrowseViewController else {
            assertionFailure()
            return
        }
        browse.exportData(nil)
    }
}

// MARK: - UISplitViewControllerDelegate

extension CustomSplitViewController: UISplitViewControllerDelegate {

    // Collapse all the view controllers onto the primary stack
    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        if secondary.viewControllers != [emptyViewController] {
            // only collapse if the right pane _isn't_ the empty state
            primary.viewControllers += secondary.viewControllers
        }
        primary.navigationBar.prefersLargeTitles = true
        secondary.viewControllers = []
        return .primary
    }

    // leave only the first view controller in the primary column
    func splitViewController(_ svc: UISplitViewController, displayModeForExpandingToProposedDisplayMode proposedDisplayMode: UISplitViewController.DisplayMode) -> UISplitViewController.DisplayMode {
        guard let top = primary.viewControllers.first else {
            assertionFailure()
            return proposedDisplayMode
        }
        let restOfStack = Array(primary.viewControllers[1...])
        primary.viewControllers = [top]
        primary.navigationBar.prefersLargeTitles = true
        secondary.viewControllers = restOfStack.isEmpty ? [emptyViewController] : restOfStack
        return .oneBesideSecondary
    }
}

// Custom navigation controller for the primary column that will push all
// navigation onto the detail pane
class StaticNavigationController: UINavigationController {
    override func show(_ vc: UIViewController, sender: Any?) {
        guard let split = splitViewController as? CustomSplitViewController else {
            assertionFailure()
            super.show(vc, sender: sender)
            return
        }
        if split.isCollapsed == true {
            super.show(vc, sender: sender)
        } else {
            // calling show from the left pane actually replaces the right pane
            split.secondary.viewControllers = [vc]
        }
    }
}
