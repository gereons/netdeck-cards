//
//  TableData.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import Foundation

class TableData<T> {
    var sections: [String]
    var values: [[T]]
    var collapsedSections: [Bool]? {
        willSet {
            assert(newValue == nil || newValue?.count == sections.count, "count mismatch")
        }
    }
    
    init(sections: [String], values: [[T]]) {
        assert(sections.count == values.count, "sections/values count mismatch")
        self.sections = sections
        self.values = values
        self.collapsedSections = nil
    }
    
    convenience init(values: [T]) {
        self.init(sections: [""], values: [values])
    }

}
