//
//  CostStats.swift
//  NetDeck
//
//  Created by Gereon Steffens on 25.12.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import CorePlot

class CostStats: Stats {
    
    init(deck: Deck) {
        super.init()
        self.useBlues = true
        
        var costs = [String: Int]()
        for cc in deck.cards.filter({ $0.card.cost >= 0 }) {
            let cost = "\(cc.card.cost)"
            costs[cost] = (costs[cost] ?? 0) + cc.count
        }
        
        let sections = costs.keys.sorted { $0 < $1 }
        let values = sections.map { [costs[$0]!] }
        
        assert(sections.count == values.count)
        
        self.tableData = TableData(sections: sections, values: values)
    }
    
    var hostingView: CPTGraphHostingView {
        return self.hostingView(for: self, identifier: "Cost")
    }
    
    func dataLabel(for plot: CPTPlot, record index: UInt) -> CPTLayer? {
        let cost = self.tableData.sections[Int(index)]
        let cards = self.tableData.values[Int(index)][0]
        
        let str = String(format: "%@ %@\n%d %@".localized(), cost, credString(cost), cards, cardsString(cards))
        return CPTTextLayer(text: str)
    }
}

