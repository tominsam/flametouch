// Copyright 2019 Thomas Insam. All rights reserved.

import ServiceDiscovery
import UIKit
import Utils

class CustomSplitViewController: UISplitViewController {

    lazy var master = with(StaticNavigationController()) {
        // Base nav VC is for iPad, then the split view is immediately
        // collapsed for phones. Collapsing unsets prefersLargeTitles.
        $0.navigationBar.prefersLargeTitles = true
    }

    lazy var emptyViewController = with(UIViewController()) {
        $0.view.backgroundColor = .systemGroupedBackground
    }

    override var delegate: UISplitViewControllerDelegate? {
        get { return self }
        set { fatalError(String(describing: newValue)) }
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        super.delegate = self
        preferredDisplayMode = .oneBesideSecondary
        primaryBackgroundStyle = .sidebar
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .opaqueSeparator
    }

    // set view for left pane
    func setMasterViewController(_ viewController: UIViewController) {
        master.viewControllers = [viewController]
        // master on left, empty nav on right
        viewControllers = [master, makeNav()]
    }

    func clearDetailViewController() {
        viewControllers = [viewControllers[0], makeNav()]
    }

    // if the list is empty it'll contain the empty vc by default to control the background color
    private func makeNav(_ viewControllers: [UIViewController] = []) -> UINavigationController {
        let vc = UINavigationController()
        vc.viewControllers = viewControllers.isEmpty ? [emptyViewController] : viewControllers
        return vc
    }

    // Menu action. It's on the split view controller because that's always
    // in the responder chain but still has a window/vc to present from
    // but the actual exporter is on the browser view controller because that's
    // where the list of services is
    @objc
    func saveExportedData() {
        guard let nav = self.viewControllers.first as? UINavigationController else {
            assertionFailure()
            return
        }
        guard let browse = nav.viewControllers.first as? BrowseViewController else {
            assertionFailure()
            return
        }
        browse.exportData()
    }
}

// MARK: - UISplitViewControllerDelegate

extension CustomSplitViewController: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, show vc: UIViewController, sender: Any?) -> Bool {
        return self.splitViewController(splitViewController, showDetail: vc, sender: sender)
    }

    func splitViewController(_: UISplitViewController, showDetail vc: UIViewController, sender _: Any?) -> Bool {
        guard let master = viewControllers.first as? UINavigationController else {
            return false
        }

        if isCollapsed {
            // When collapsed, the master navigation controller is the main stack
            master.pushViewController(vc, animated: true)
        } else {
            // reset the detail stack to show this vc only
            viewControllers = [master, makeNav([vc])]
        }
        return true
    }

    // When we collapse from 2 panes to 1 pane, we move all the views onto the new master view controller
    func splitViewController(_: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        guard let master = primaryViewController as? UINavigationController, let detail = secondaryViewController as? UINavigationController else {
            return true
        }
        if detail.viewControllers != [emptyViewController] {
            // only collapse if the right pane _isn't_ the empty state
            master.viewControllers += detail.viewControllers
        }
        master.navigationBar.prefersLargeTitles = false
        return true
    }

    // When we expand from 1 pane to 2 panes, pull all but the first view from the primary and return
    // a new navigation view controller as secondary that contains the rest of the stack.
    func splitViewController(_: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        guard let master = primaryViewController as? UINavigationController, let top = master.viewControllers.first else {
            return makeNav()
        }
        let restOfStack = Array(master.viewControllers[1...])
        master.viewControllers = [top]
        master.navigationBar.prefersLargeTitles = true
        return makeNav(restOfStack)
    }
}

class StaticNavigationController: UINavigationController {
    override func show(_ vc: UIViewController, sender: Any?) {
        if (parent as? UISplitViewController)?.isCollapsed == true {
            super.show(vc, sender: sender)
        } else {
            // calling show from the left pane actually replaces the right pane
            super.showDetailViewController(vc, sender: sender)
        }
    }
}
