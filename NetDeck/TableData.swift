//
//  TableData.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

@objc class TableData: NSObject {

    var sections: NSArray
    var values: NSArray
    var collapsedSections: [Bool]?
    
    init(sections: NSArray, andValues values: NSArray) {
        assert(sections.count == values.count, "sections/values count mismatch")
        self.sections = sections
        self.values = values
        self.collapsedSections = nil
        super.init()
    }
    
    convenience init(values: NSArray) {
        self.init(sections: [""], andValues: [values])
    }
    
    class func convertPacksData(rawPacks: TableData) -> TableData {
        let strValues = NSMutableArray()
        for packs in rawPacks.values as! [[Pack]] {
            let strings = NSMutableArray()
            for pack in packs {
                strings.addObject(pack.name)
            }
            strValues.addObject(strings)
        }
        
        let stringPacks = TableData(sections:rawPacks.sections, andValues:strValues)
        stringPacks.collapsedSections = rawPacks.collapsedSections
        return stringPacks
    }
}
