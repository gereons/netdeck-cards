//
//  UIUtilities.swift
//  NetDeck
//
//  Created by Gereon Steffens on 02.04.18.
//  Copyright © 2018 Gereon Steffens. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(rgb: UInt) {
        let r = CGFloat((rgb & 0xFF0000) >> 16)
        let g = CGFloat((rgb & 0x00FF00) >> 8)
        let b = CGFloat((rgb & 0x0000FF) >> 0)
        self.init(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
    }
}

extension UIEdgeInsets {
    static func forScreen(bottom: CGFloat = 0) -> UIEdgeInsets {
        var top: CGFloat = 64
        if #available(iOS 11.0, *) {
            top = 0
        }
        return UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
    }
}

extension UIScrollView {
    func scrollFix() {
        if #available(iOS 11.0, *) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentBehavior.never
        }
    }
}

extension UIBarButtonItem {
    var frame: CGRect {
        guard let view = self.value(forKey: "view") as? UIView else {
            return CGRect.zero
        }
        return view.frame
    }
}
