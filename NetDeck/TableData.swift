//
//  TableData.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

class TableData: NSObject {

    var sections: [String]
    var values: NSArray
    var collapsedSections: [Bool]? {
        willSet {
            assert(newValue == nil || newValue?.count == sections.count, "count mismatch")
        }
    }
    
    init(sections: [String], andValues values: NSArray) {
        assert(sections.count == values.count, "sections/values count mismatch")
        self.sections = sections
        self.values = values
        self.collapsedSections = nil
        super.init()
    }
    
    convenience init(values: NSArray) {
        self.init(sections: [""], andValues: [values])
    }
    
    class func convertPacksData(_ rawPacks: TableData) -> TableData {
        let strValues = NSMutableArray()
        for packs in rawPacks.values as! [[Pack]] {
            let strings = NSMutableArray()
            for pack in packs {
                strings.add(pack.name)
            }
            strValues.add(strings)
        }
        
        let stringPacks = TableData(sections:rawPacks.sections, andValues:strValues)
        stringPacks.collapsedSections = rawPacks.collapsedSections
        return stringPacks
    }
}

// strongly-typed variant, where both producer and consumer are Swift
class TypedTableData<T> {
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
    
    convenience init(untyped: TableData) {
        self.init(sections: untyped.sections, values: untyped.values as! [[T]])
    }
}
