//
//  UIAlert+NetDeck.swift
//  NetDeck
//
//  Created by Gereon Steffens on 23.12.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

extension UIAlertAction {
    typealias ActionHandler = (UIAlertAction) -> Void
    
    static func actionSheetCancel(_ handler: ActionHandler?) -> UIAlertAction {
        let title = Device.isIpad ? "" : "Cancel".localized()
        return UIAlertAction(title: title, style: .cancel, handler: handler)
    }
    
    static func alertCancel(_ handler: ActionHandler?) -> UIAlertAction {
        return UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: handler)
    }
    
    static func action(title: String, handler: ActionHandler?) -> UIAlertAction {
        return UIAlertAction(title: title, style: .default, handler: handler)
    }
    
    convenience init(title: String, handler: ActionHandler?) {
        self.init(title: title, style: .default, handler: handler)
    }
}

extension UIAlertController {
    static func alert(title: String? = nil, message: String? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        return alert
    }
    
    static func actionSheet(title: String?, message: String?) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        return alert
    }
    
    static func alert(withTitle title: String?, message: String? = nil, button: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: button, style: .default, handler: nil))
        alert.show()
    }
    
    func show() {
        self.present(animated: false, completion: nil)
    }
    
    private typealias CompletionHandler = () -> Void
    
    private func present(animated: Bool, completion: CompletionHandler?) {
        guard let root = UIApplication.shared.keyWindow?.rootViewController else { return }
        self.presentFromController(root, animated: animated, completion: completion)
    }
    
    private func presentFromController(_ controller: UIViewController, animated: Bool, completion: CompletionHandler?) {
        if let nav = controller as? UINavigationController {
            if let visible = nav.visibleViewController {
                self.presentFromController(visible, animated: animated, completion: completion)
            }
        } else if let tab = controller as? UITabBarController {
            if let selected = tab.selectedViewController {
                self.presentFromController(selected, animated:  animated, completion: completion)
            }
        } else {
            controller.present(self, animated: animated, completion: completion)
        }
    }
}
