//
//  DetailViewManager.swift
//  NetDeck
//
//  Created by Gereon Steffens on 26.05.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

class DetailViewManager: NSObject, UISplitViewControllerDelegate {

    // Things for IB
    // The split view this class will be managing.
    @IBOutlet var splitViewController: UISplitViewController?

    // The presently displayed detail view controller.  This is modified by the various
    // view controllers in the navigation pane of the split view controller.
    @IBOutlet var detailViewController: UINavigationController? {
        willSet {
            self.detailViewController = newValue
            
            let navigationViewController = self.splitViewController?.viewControllers.first
            var viewControllers = [UIViewController]()
            if navigationViewController != nil {
                viewControllers.append(navigationViewController!)
            }
            if self.detailViewController != nil {
                viewControllers.append(self.detailViewController!)
            }
            self.splitViewController?.viewControllers = viewControllers
        }
    }
    
    func splitViewController(_ svc: UISplitViewController, shouldHide vc: UIViewController, in orientation: UIInterfaceOrientation) -> Bool {
        return UIInterfaceOrientationIsPortrait(orientation)
    }
}
