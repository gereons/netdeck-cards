//
//  TableData.swift
//  NetDeck
//
//  Created by Gereon Steffens on 14.11.15.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import Foundation

@objc class TableData: NSObject {

    var sections: NSArray!
    var values: NSArray!
    var collapsedSections: [Bool]?
    
    init(sections: NSArray, andValues values: NSArray) {
        super.init()
        
        assert(sections.count == values.count, "sections/values count mismatch")
        self.sections = sections
        self.values = values
        self.collapsedSections = nil
    }
    
    convenience init(values: NSArray) {
        self.init(sections: [""], andValues:[values])
    }
}