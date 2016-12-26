//
//  StrengthStats.swift
//  NetDeck
//
//  Created by Gereon Steffens on 25.12.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

import CorePlot

class StrengthStats: Stats {
    
    init(deck: Deck) {
        super.init()
        
        var strengths = [Int: Int]()
        for cc in deck.cards.filter({ $0.card.strength >= 0 }) {
            let str = cc.card.strength
            strengths[str] = (strengths[str] ?? 0) + cc.count
        }
        
        let sections = strengths.keys.sorted { $0 < $1 }
        let values = sections.map { strengths[$0]! }
        
        assert(sections.count == values.count)
        
        self.tableData = TableData(sections: sections as NSArray, andValues: values as NSArray)
    }
    
    var hostingView: CPTGraphHostingView {
        return self.hostingView(for: self, identifier: "Strength")
    }
    
    func dataLabel(for plot: CPTPlot, record index: UInt) -> CPTLayer? {
        let strength = self.tableData.sections[Int(index)] as! Int
        let cards = self.tableData.values[Int(index)] as! Int
    
        let str = String(format: "Strength %d\n%d %@".localized(), strength, cards, cardsString(cards))
        return CPTTextLayer(text: str)
    }
    
    func cardsString(_ c: Int) -> String {
        return c == 1 ? "Card".localized() : "Cards".localized()
    }
}
