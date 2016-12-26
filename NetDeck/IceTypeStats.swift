//
//  IceTypeStats.swift
//  NetDeck
//
//  Created by Gereon Steffens on 25.12.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import CorePlot

class IceTypeStats: Stats {
    
    private let iceCount: Int
    
    init(deck: Deck) {
        var count = 0
        var types = [String: Int]()
        for cc in deck.cards.filter({$0.card.type == .ice}) {
            count += cc.count
            
            let type = cc.card.iceType
            types[type] = (types[type] ?? 0) + cc.count
        }
        
        self.iceCount = count
        super.init()
        
        let sections = types.keys.sorted { $0 < $1 }
        let values = sections.map { types[$0]! }
        
        assert(sections.count == values.count)
        
        self.tableData = TableData(sections: sections as NSArray, andValues: values as NSArray)
    }
    
    var hostingView: CPTGraphHostingView {
        return self.hostingView(for: self, identifier: "Ice Type")
    }
    
    func dataLabel(for plot: CPTPlot, record index: UInt) -> CPTLayer? {
        let type = self.tableData.sections[Int(index)] as! String
        let cards = self.tableData.values[Int(index)] as! Int
        
        let pct = Float(cards) * 100.0 / Float(self.iceCount)
        
        let str = String(format: "%@: %d\n%.1f%%", type, cards, pct)
        return CPTTextLayer(text: str)
    }
    
}
