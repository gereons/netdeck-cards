//
//  MiscUtilities.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.12.15.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Foundation
import SDCAlertView

struct Constant {
    static let kANY = "Any"
    static let arrow = " ▾"
}

extension String {
    func localized() -> String {
        return NSLocalizedString(self, comment: "")
    }
    
    var length: Int {
        return self.characters.count
    }
    
    func appendPathComponent(_ component: String) -> String {
        return (self as NSString).appendingPathComponent(component)
    }
    
    func trimmed() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    func checked(_ checked: Bool) -> String {
        return checked ? self + " ✓" : self
    }
}

extension Collection {
    /// Return a copy of `self` with its elements shuffled
    func shuffled() -> [Iterator.Element] {
        var list = Array(self)
        list.shuffle()
        return list
    }
}

extension MutableCollection where Index == Int, IndexDistance == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffle() {
        // empty and single-element collections don't shuffle
        if count < 2 {
            return
        }
        
        for i in 0 ..< count - 1 {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            guard i != j else { continue }
            swap(&self[i], &self[j])
        }
    }
}

extension UIColor {
    convenience init(r: Int, g: Int, b: Int) {
        self.init(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: 1.0)
    }
    
    convenience init(rgb: UInt) {
        let r = CGFloat((rgb & 0xFF0000) >> 16)
        let g = CGFloat((rgb & 0x00FF00) >> 8)
        let b = CGFloat((rgb & 0x0000FF) >> 0)
        self.init(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
    }
    
    class func colorWithRGB(_ rgb : UInt) -> UIColor {
        return UIColor(rgb: rgb)
    }
}

extension NSRange {
    func stringRangeForText(_ string: String) -> Range<String.Index> {
        let start = string.characters.index(string.startIndex, offsetBy: self.location)
        let end = string.characters.index(start, offsetBy: self.length)
        return start ..< end
    }
}

class CustomAlertVisualStyle: AlertVisualStyle {
    override init(alertStyle: AlertControllerStyle) {
        super.init(alertStyle: alertStyle)
        self.backgroundColor = .white
    }
}

@available(iOS, deprecated: 1.0, message: "I'm not deprecated, please **FIXME**")
public func FIXME(_ msg: String="") {}
