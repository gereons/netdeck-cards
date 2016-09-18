//
//  MiscUtilities.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.12.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation
import SDCAlertView

class Constant: NSObject {
    static let kANY = "Any"
}

extension String {
    func localized() -> String {
        return NSLocalizedString(self, comment: "")
    }
    
    var length: Int {
        return self.characters.count
    }
    
    func stringByAppendingPathComponent(_ component: String) -> String {
        return (self as NSString).appendingPathComponent(component)
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
}

extension Collection {
    /// Return a copy of `self` with its elements shuffled
    func shuffle() -> [Iterator.Element] {
        var list = Array(self)
        list.shuffleInPlace()
        return list
    }
}

extension MutableCollection where Index == Int, IndexDistance == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffleInPlace() {
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
    class func colorWithRGB(_ rgb: UInt) -> UIColor! {
        let r = CGFloat((rgb & 0xFF0000) >> 16)
        let g = CGFloat((rgb & 0x00FF00) >> 8)
        let b = CGFloat((rgb & 0x0000FF) >> 0)
        return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
    }
}

extension NSRange {
    func stringRangeForText(_ string: String) -> Range<String.Index> {
        let start = string.characters.index(string.startIndex, offsetBy: self.location)
        let end = string.characters.index(start, offsetBy: self.length)
        // 7return Range<String.Index>(start: start, end: end)
        return start ..< end
    }
}

/*
class CustomAlertVisualStyle: AlertVisualStyle {
    override init(alertStyle: AlertControllerStyle) {
        super.init(alertStyle: alertStyle)
        self.backgroundColor = UIColor.white
    }
}
*/

@available(iOS, deprecated: 1.0, message: "I'm not deprecated, please **FIXME**")
func FIXME(_ msg: String="") {}
