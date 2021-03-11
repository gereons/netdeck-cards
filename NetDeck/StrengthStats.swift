//
//  StrengthStats.swift
//  NetDeck
//
//  Created by Gereon Steffens on 25.12.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import CorePlot

class StrengthStats: Stats {
    
    init(deck: Deck) {
        super.init()
        self.useBlues = true
        
        var strengths = [String: Int]()
        for cc in deck.cards.filter({ $0.card.strength >= 0 }) {
            let str = "\(cc.card.strength)"
            strengths[str] = (strengths[str] ?? 0) + cc.count
        }
        
        let sections = strengths.keys.sorted { $0 < $1 }
        let values = sections.map { [strengths[$0]!] }
        
        assert(sections.count == values.count)
        
        self.tableData = TableData(sections: sections, values: values)
    }
    
    var hostingView: CPTGraphHostingView {
        return self.hostingView(for: self, identifier: "Strength")
    }
    
    func dataLabel(for plot: CPTPlot, record index: UInt) -> CPTLayer? {
        let strength = self.tableData.sections[Int(index)]
        let cards = self.tableData.values[Int(index)][0]
    
        let str = String(format: "Strength %@\n%d %@".localized(), strength, cards, cardsString(cards))
        let style = CPTMutableTextStyle()
        style.color = CPTColor(uiColor: .label)
        return CPTTextLayer(text: str, style: style)
    }
}
