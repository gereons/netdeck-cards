//
//  KeyboardHandling
//  NetDeck
//
//  Created by Gereon Steffens on 15.04.17.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
//

import UIKit

/// frame and animation data extracted from a keyboard show/hide notification
struct KeyboardInfo {
    let beginFrame: CGRect
    let endFrame: CGRect
    let animationDuration: TimeInterval

    init?(notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let beginFrame = userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue,
            let endFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue,
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval
        else {
            return nil
        }

        self.beginFrame = beginFrame.cgRectValue
        self.endFrame = endFrame.cgRectValue
        self.animationDuration = duration
    }

    var keyboardHeight: CGFloat {
        return self.endFrame.height
    }
}

protocol KeyboardHandling: class {

    func keyboardWillShow(_ info: KeyboardInfo)

    func keyboardWillHide(_ info: KeyboardInfo)

}

class KeyboardObserver: NSObject {

    private weak var handler: KeyboardHandling!

    required init(handler: KeyboardHandling) {
        self.handler = handler
        super.init()
        self.startObserving()
    }

    deinit {
        self.stopObserving()
    }

    func startObserving() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        nc.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func stopObserving() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let info = KeyboardInfo(notification: notification) else {
            return
        }

        self.handler.keyboardWillShow(info)
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        guard let info = KeyboardInfo(notification: notification) else {
            return
        }
        
        self.handler.keyboardWillHide(info)
    }
}
