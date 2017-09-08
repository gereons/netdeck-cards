//
//  CardTypetats.swift
//  NetDeck
//
//  Created by Gereon Steffens on 25.12.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import CorePlot

class CardTypeStats: Stats {

    private let deckSize: Int
    
    init(deck: Deck) {
        self.deckSize = deck.size
        super.init()
        
        var types = [String: Int]()
        for cc in deck.cards {
            let card = cc.card
            let type = card.type == .program ? card.programType : card.typeStr.localized()
            
            types[type] = (types[type] ?? 0) + cc.count
        }
        
        let sections = types.keys.sorted { $0 < $1 }
        let values = sections.map { [types[$0]!] }
        
        assert(sections.count == values.count)
        
        self.tableData = TableData(sections: sections, values: values)
    }
    
    var hostingView: CPTGraphHostingView {
        return self.hostingView(for: self, identifier: "Card Type")
    }
    
    func dataLabel(for plot: CPTPlot, record index: UInt) -> CPTLayer? {
        let type = self.tableData.sections[Int(index)]
        let cards = self.tableData.values[Int(index)][0]
        
        let pct = Float(cards) * 100.0 / Float(self.deckSize)
        
        let str = String(format: "%@: %d\n%.1f%%", type, cards, pct)
        return CPTTextLayer(text: str)
    }
    
}
