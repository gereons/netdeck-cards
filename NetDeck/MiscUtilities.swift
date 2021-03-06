//
//  MiscUtilities.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.12.15.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import Foundation

extension String {
    func localized() -> String {
        return NSLocalizedString(self, comment: "")
    }
    
    func appendPathComponent(_ component: String) -> String {
        return (self as NSString).appendingPathComponent(component)
    }
    
    func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespaces)
    }
    
    func checked(_ checked: Bool) -> String {
        return checked ? self + " ✓" : self
    }
}

// MARK: - safe subscripts

extension Array {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return (index >= 0 && index < self.count) ? self[index] : nil
    }
}

extension Array where Element: RandomAccessCollection, Element.Index == Int {
    /// for 2D arrays: Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (row: Int, column: Int) -> Element.Iterator.Element? {
        if row >= 0 && row < self.count {
            let arr = self[row]
            if column >= 0 && column <= arr.count {
                return arr[column]
            }
        }
        return nil
    }

    subscript (indexPath: IndexPath) -> Element.Iterator.Element? {
        return self[indexPath.section, indexPath.row]
    }
}

extension NSRange {
    func stringRangeForText(_ string: String) -> Range<String.Index> {
        let start = string.index(string.startIndex, offsetBy: self.location)
        let end = string.index(start, offsetBy: self.length)
        return start ..< end
    }
}
